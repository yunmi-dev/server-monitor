// tests/auth_handlers.rs
use actix_web::{test, web, App};
use chrono::Utc;
use uuid::Uuid;
use rust_server::{
    auth::{handlers::{LoginRequest, login, logout, register}, jwt::Claims, types::*}, 
    config::{ServerConfig, AuthConfig}, 
    db::models::*,
};
use mockall::predicate::*;
use mockall::mock;

// Repository 모의 객체 생성
mock! {
    Repository {
        async fn get_user_by_email(&self, email: &str) -> Result<Option<User>, anyhow::Error>;
        async fn create_user(&self, user: User) -> Result<User, anyhow::Error>;
        async fn update_user(&self, user: User) -> Result<User, anyhow::Error>;
        async fn invalidate_refresh_tokens(&self, user_id: &str) -> Result<(), anyhow::Error>;
        async fn end_user_sessions(&self, user_id: &str) -> Result<(), anyhow::Error>;
        async fn clear_user_cache(&self, user_id: &str) -> Result<(), anyhow::Error>;
    }
}

#[actix_rt::test]
async fn test_login_success() {
    // 설정 준비
    let config = web::Data::new(ServerConfig {
        auth: AuthConfig {
            jwt_secret: "test_secret".to_string(),
            access_token_expire: 3600,
            refresh_token_expire: 86400,
            token_expiration_hours: 24,
        },
        ..Default::default()
    });

    // 테스트용 사용자 데이터
    let test_user = User {
        id: Uuid::new_v4().to_string(),
        email: "test@example.com".to_string(),
        password_hash: Some("$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLR/2ARoxtq".to_string()), // "password123"의 해시
        name: "Test User".to_string(),
        role: UserRole::User,
        provider: AuthProvider::Email,
        profile_image_url: None,
        created_at: Utc::now(),
        updated_at: Utc::now(),
        last_login_at: Some(Utc::now()),
    };

    // Repository 모의 객체 설정
    let mut mock_repo = MockRepository::new();
    mock_repo
        .expect_get_user_by_email()
        .with(eq("test@example.com"))
        .times(1)
        .returning(move |_| Ok(Some(test_user.clone())));

    // 로그인 요청 데이터
    let login_req = LoginRequest {
        email: "test@example.com".to_string(),
        password: "password123".to_string(),
    };

    // HTTP 요청 테스트
    let app = test::init_service(
        App::new()
            .app_data(config)
            .app_data(web::Data::new(mock_repo))
            .service(login),
    )
    .await;

    let resp = test::TestRequest::post()
        .uri("/login")
        .set_json(&login_req)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: AuthResponse = test::read_body_json(resp).await;
    assert!(!body.token.is_empty());
    assert!(!body.refresh_token.is_empty());
    assert_eq!(body.user.email, "test@example.com");
}

#[actix_rt::test]
async fn test_login_invalid_credentials() {
    // 설정 준비
    let config = web::Data::new(ServerConfig {
        auth: AuthConfig {
            jwt_secret: "test_secret".to_string(),
            access_token_expire: 3600,
            refresh_token_expire: 86400,
            token_expiration_hours: 24,
        },
        ..Default::default()
    });

    // Repository 모의 객체 설정
    let mut mock_repo = MockRepository::new();
    mock_repo
        .expect_get_user_by_email()
        .with(eq("test@example.com"))
        .times(1)
        .returning(|_| Ok(None));

    // 잘못된 로그인 요청
    let login_req = LoginRequest {
        email: "test@example.com".to_string(),
        password: "wrongpassword".to_string(),
    };

    // HTTP 요청 테스트
    let app = test::init_service(
        App::new()
            .app_data(config)
            .app_data(web::Data::new(mock_repo))
            .service(login),
    )
    .await;

    let resp = test::TestRequest::post()
        .uri("/login")
        .set_json(&login_req)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 401);
}

#[actix_rt::test]
async fn test_register_success() {
    // 설정 준비
    let config = web::Data::new(ServerConfig {
        auth: AuthConfig {
            jwt_secret: "test_secret".to_string(),
            access_token_expire: 3600,
            refresh_token_expire: 86400,
            token_expiration_hours: 24,
        },
        ..Default::default()
    });

    // Repository 모의 객체 설정
    let mut mock_repo = MockRepository::new();
    mock_repo
        .expect_get_user_by_email()
        .with(eq("new@example.com"))
        .times(1)
        .returning(|_| Ok(None));
    
    mock_repo
        .expect_create_user()
        .times(1)
        .returning(|user| Ok(user));

    // 회원가입 요청 데이터
    let register_req = RegisterRequest {
        name: "New User".to_string(),
        email: "new@example.com".to_string(),
        password: "newpassword123".to_string(),
    };

    // HTTP 요청 테스트
    let app = test::init_service(
        App::new()
            .app_data(config)
            .app_data(web::Data::new(mock_repo))
            .service(register),
    )
    .await;

    let resp = test::TestRequest::post()
        .uri("/register")
        .set_json(&register_req)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);

    let body: AuthResponse = test::read_body_json(resp).await;
    assert!(!body.token.is_empty());
    assert!(!body.refresh_token.is_empty());
    assert_eq!(body.user.email, "new@example.com");
    assert_eq!(body.user.name, "New User");
}

#[actix_rt::test]
async fn test_logout_success() {
    // Repository 모의 객체 설정
    let mut mock_repo = MockRepository::new();
    mock_repo
        .expect_invalidate_refresh_tokens()
        .times(1)
        .returning(|_| Ok(()));
    
    mock_repo
        .expect_end_user_sessions()
        .times(1)
        .returning(|_| Ok(()));
    
    mock_repo
        .expect_clear_user_cache()
        .times(1)
        .returning(|_| Ok(()));

    // Claims 설정
    let claims = Claims {
        sub: "test_user_id".to_string(),
        email: "test@example.com".to_string(),
        role: UserRole::User,
        exp: Utc::now().timestamp() + 3600,
        iat: Utc::now().timestamp(),
        token_type: "access".to_string(),
    };

    // HTTP 요청 테스트
    let app = test::init_service(
        App::new()
            .app_data(web::Data::new(mock_repo))
            .service(logout),
    )
    .await;

    let resp = test::TestRequest::post()
        .uri("/logout")
        .set_json(&claims)
        .send_request(&app)
        .await;

    assert_eq!(resp.status(), 200);
}