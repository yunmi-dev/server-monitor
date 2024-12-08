// src/auth/handlers.rs
use actix_web::{post, web, HttpResponse};
use chrono::Utc;
use jsonwebtoken::{encode, EncodingKey, Header};
use reqwest::Client;
use uuid::Uuid;
use serde::Deserialize;
use crate::auth::utils::verify_password;
use crate::auth::types::{AuthResponse, RegisterRequest, SocialLoginRequest, UserResponse};
use crate::auth::jwt::Claims;
use crate::auth::utils::hash_password;
use crate::config::ServerConfig;
use crate::db::models::{User, UserRole, AuthProvider};
use crate::db::repository::Repository;
use crate::error::AppError;
use serde_json::json;

#[derive(Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[post("/login")]
pub async fn login(
    req: web::Json<LoginRequest>,
    repo: web::Data<Repository>,
    config: web::Data<ServerConfig>,
) -> Result<HttpResponse, AppError> {
    let user = match repo.get_user_by_email(&req.email).await? {
        Some(user) => user,
        None => return Err(AppError::AuthError("Invalid credentials".into())),
    };

    if !verify_password(&req.password, user.password_hash.as_ref().unwrap_or(&String::new()))? {
        return Err(AppError::AuthError("Invalid credentials".into()));
    }

    let tokens = generate_tokens(&user, &config)?;
    Ok(HttpResponse::Ok().json(create_auth_response(user, tokens)))
}

#[post("/register")]
pub async fn register(
    req: web::Json<RegisterRequest>,
    repo: web::Data<Repository>,
    config: web::Data<ServerConfig>,
) -> Result<HttpResponse, AppError> {
    if let Some(_) = repo.get_user_by_email(&req.email).await? {
        return Err(AppError::BadRequest("Email already exists".into()));
    }

    let password_hash = hash_password(&req.password)?;

    let new_user = User {
        id: Uuid::new_v4().to_string(),
        email: req.email.clone(),
        password_hash: Some(password_hash),
        name: req.name.clone(),
        role: UserRole::User,
        provider: AuthProvider::Email,
        profile_image_url: None,
        created_at: Utc::now(),
        updated_at: Utc::now(),
        last_login_at: Some(Utc::now()),
    };

    let user = repo.create_user(new_user).await?;
    let tokens = generate_tokens(&user, &config)?;

    Ok(HttpResponse::Ok().json(create_auth_response(user, tokens)))
}

// 임시 방편으로 테스트용 이메일 사용
#[post("/social-login")]
pub async fn social_login(
    req: web::Json<SocialLoginRequest>,
    repo: web::Data<Repository>,
    // http_client: web::Data<Client>,
    config: web::Data<ServerConfig>,
) -> Result<HttpResponse, AppError> {
    // 클라이언트가 보낸 이메일 사용
    let email = req.email.clone().unwrap_or_else(|| "test@example.com".to_string());
    let temp_password = format!("{}_{}", req.provider, Uuid::new_v4());  // 임시 패스워드 생성
    let password_hash = hash_password(&temp_password)?;  // 해시 생성
    
    let new_user = User {
        id: Uuid::new_v4().to_string(),
        email: email.clone(),
        password_hash: Some(password_hash),  // 임시 패스워드 해시 사용
        name: email.split('@').next().unwrap_or("User").to_string(),
        role: UserRole::User,
        provider: match req.provider.as_str() {
            "facebook" => AuthProvider::Facebook,
            "google" => AuthProvider::Google,
            "kakao" => AuthProvider::Kakao,
            "apple" => AuthProvider::Apple,
            _ => return Err(AppError::BadRequest("Unsupported provider".into())),
        },
        profile_image_url: None,
        created_at: Utc::now(),
        updated_at: Utc::now(),
        last_login_at: Some(Utc::now()),
    };

    // 기존 사용자 확인
    let user = match repo.get_user_by_email(&email).await? {
        Some(mut existing_user) => {
            existing_user.last_login_at = Some(Utc::now());
            existing_user.updated_at = Utc::now();
            repo.update_user(existing_user).await?
        },
        None => repo.create_user(new_user).await?
    };
    
    let tokens = generate_tokens(&user, &config)?;
    Ok(HttpResponse::Ok().json(create_auth_response(user, tokens)))
}

async fn handle_google_login(
    token: &str,
    repo: web::Data<Repository>,
    http_client: web::Data<Client>,
    config: web::Data<ServerConfig>,
) -> Result<HttpResponse, AppError> {
    let token_info = http_client
        .get("https://oauth2.googleapis.com/tokeninfo")
        .query(&[("id_token", token)])
        .send()
        .await
        .map_err(|e| AppError::ExternalService(format!("Google API error: {}", e)))?
        .json::<serde_json::Value>()
        .await
        .map_err(|e| AppError::ExternalService(format!("Google API response parse error: {}", e)))?;

    let email = token_info["email"]
        .as_str()
        .ok_or_else(|| AppError::BadRequest("Invalid token: no email found".into()))?;

    let name = token_info["name"].as_str().map(|s| s.to_string());
    let picture = token_info["picture"].as_str().map(|s| s.to_string());

    let user = handle_user_creation(email, name, picture, AuthProvider::Google, repo).await?;
    let tokens = generate_tokens(&user, &config)?;

    Ok(HttpResponse::Ok().json(create_auth_response(user, tokens)))
}

async fn handle_kakao_login(
    token: &str,
    repo: web::Data<Repository>,
    http_client: web::Data<Client>,
    config: web::Data<ServerConfig>,
) -> Result<HttpResponse, AppError> {
    let user_info = http_client
        .get("https://kapi.kakao.com/v2/user/me")
        .header("Authorization", format!("Bearer {}", token))
        .send()
        .await
        .map_err(|e| AppError::ExternalService(format!("Kakao API error: {}", e)))?
        .json::<serde_json::Value>()
        .await
        .map_err(|e| AppError::ExternalService(format!("Kakao API response parse error: {}", e)))?;

    let kakao_account = user_info["kakao_account"]
        .as_object()
        .ok_or_else(|| AppError::BadRequest("Invalid Kakao response format".into()))?;

    let email = kakao_account["email"]
        .as_str()
        .ok_or_else(|| AppError::BadRequest("Email not found in Kakao account".into()))?;

    let profile = kakao_account["profile"]
        .as_object()
        .ok_or_else(|| AppError::BadRequest("Profile not found in Kakao account".into()))?;

    let name = profile["nickname"].as_str().map(|s| s.to_string());
    let picture = profile["profile_image_url"].as_str().map(|s| s.to_string());

    let user = handle_user_creation(email, name, picture, AuthProvider::Kakao, repo).await?;
    let tokens = generate_tokens(&user, &config)?;

    Ok(HttpResponse::Ok().json(create_auth_response(user, tokens)))
}

async fn handle_apple_login(
    token: &str,
    repo: web::Data<Repository>,
    _http_client: web::Data<Client>,
    config: web::Data<ServerConfig>,
) -> Result<HttpResponse, AppError> {
    let claims = jsonwebtoken::decode::<serde_json::Value>(
        token,
        &jsonwebtoken::DecodingKey::from_secret(config.auth.jwt_secret.as_bytes()),
        &jsonwebtoken::Validation::default(),
    )
    .map_err(|e| AppError::BadRequest(format!("Invalid Apple token: {}", e)))?;

    let email = claims
        .claims["email"]
        .as_str()
        .ok_or_else(|| AppError::BadRequest("Email not found in Apple token".into()))?;

    let name = claims.claims["name"].as_str().map(|s| s.to_string());
    let user = handle_user_creation(email, name, None, AuthProvider::Apple, repo).await?;
    let tokens = generate_tokens(&user, &config)?;

    Ok(HttpResponse::Ok().json(create_auth_response(user, tokens)))
}

async fn handle_facebook_login(
    // token: &str,
    repo: web::Data<Repository>,
    // http_client: web::Data<Client>,
    config: web::Data<ServerConfig>,
) -> Result<HttpResponse, AppError> {
    // 클라이언트 데이터에서 이메일을 직접 사용하도록 변경
    let email = "test@example.com"; // 테스트용 고정 이메일
    let name = Some("Test User".to_string()); // 테스트용 이름
    
    // 즉시 사용자 생성/업데이트 처리
    let user = handle_user_creation(
        email,
        name,
        None,
        AuthProvider::Facebook,
        repo
    ).await?;
    
    let tokens = generate_tokens(&user, &config)?;
    Ok(HttpResponse::Ok().json(create_auth_response(user, tokens)))
}

#[post("/logout")]
pub async fn logout(
    repo: web::Data<Repository>,
    claims: Claims,
) -> Result<HttpResponse, AppError> {
    // 리프레시 토큰 무효화
    repo.invalidate_refresh_tokens(&claims.sub).await?;
    
    // 활성 세션 종료
    repo.end_user_sessions(&claims.sub).await?;
    
    // 캐시된 사용자 데이터 정리
    repo.clear_user_cache(&claims.sub).await?;

    Ok(HttpResponse::Ok().json(json!({
        "success": true,
        "message": "Successfully logged out"
    })))
}

async fn handle_user_creation(
    email: &str,
    name: Option<String>,
    profile_image: Option<String>,
    provider: AuthProvider,
    repo: web::Data<Repository>,
) -> Result<User, AppError> {
    if let Some(mut user) = repo.get_user_by_email(email).await? {
        if user.provider == provider {
            if let Some(new_name) = name {
                user.name = new_name;
            }
            user.profile_image_url = profile_image;
            user.last_login_at = Some(Utc::now());
            user.updated_at = Utc::now();
            Ok(repo.update_user(user).await?)
        } else {
            Err(AppError::BadRequest(format!(
                "Email already exists with different provider: {}",
                user.provider
            )))
        }
    } else {
        let new_user = User {
            id: Uuid::new_v4().to_string(),
            email: email.to_string(),
            password_hash: None,
            name: name.unwrap_or_else(|| email.split('@').next().unwrap_or("User").to_string()),
            role: UserRole::User,
            provider,
            profile_image_url: profile_image,
            created_at: Utc::now(),
            updated_at: Utc::now(),
            last_login_at: Some(Utc::now()),
        };
        Ok(repo.create_user(new_user).await?)
    }
}


fn generate_tokens(user: &User, config: &ServerConfig) -> Result<(String, String), AppError> {
    let now = Utc::now().timestamp();

    let access_claims = Claims {
        sub: user.id.clone(),
        email: user.email.clone(),  // 추가
        role: user.role.clone(),    // 추가
        exp: now + config.auth.access_token_expire,
        iat: now,
        token_type: "access".to_string(),
    };

    let refresh_claims = Claims {
        sub: user.id.clone(),
        email: user.email.clone(),  // 추가
        role: user.role.clone(),    // 추가
        exp: now + config.auth.refresh_token_expire,
        iat: now,
        token_type: "refresh".to_string(),
    };

    let access_token = encode(
        &Header::default(),
        &access_claims,
        &EncodingKey::from_secret(config.auth.jwt_secret.as_bytes()),
    )
    .map_err(|e| AppError::InternalError(format!("Access token generation failed: {}", e)))?;

    let refresh_token = encode(
        &Header::default(),
        &refresh_claims,
        &EncodingKey::from_secret(config.auth.jwt_secret.as_bytes()),
    )
    .map_err(|e| AppError::InternalError(format!("Refresh token generation failed: {}", e)))?;

    Ok((access_token, refresh_token))
}

pub fn create_auth_response(user: User, tokens: (String, String)) -> AuthResponse {
    AuthResponse {
        token: tokens.0,
        refresh_token: tokens.1,
        user: UserResponse::from(user),
    }
}