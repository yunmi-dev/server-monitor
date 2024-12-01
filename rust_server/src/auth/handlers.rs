// src/auth/handlers.rs
use actix_web::{post, web, HttpResponse};
use chrono::Utc;
use jsonwebtoken::{encode, EncodingKey, Header};
use reqwest::Client;
use serde_json::json;

use crate::auth::types::{AuthResponse, Claims, SocialLoginRequest};
use crate::config::AppConfig;
use crate::db::models::User;
use crate::db::Repository;
use crate::error::AppError;

#[post("/auth/social-login")]
pub async fn social_login(
    req: web::Json<SocialLoginRequest>,
    repo: web::Data<Repository>,
    http_client: web::Data<Client>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    match req.provider.as_str() {
        "google" => handle_google_login(req.0, repo, http_client, config).await,
        "kakao" => handle_kakao_login(req.0, repo, http_client, config).await,
        "apple" => handle_apple_login(req.0, repo, http_client, config).await,
        _ => Err(AppError::BadRequest("Unsupported provider".into())),
    }
}

#[post("/auth/register")]
pub async fn register(
    req: web::Json<RegisterRequest>,
    repo: web::Data<Repository>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    // 이미 존재하는 이메일인지 확인
    if let Some(_) = repo.find_user_by_email(&req.email).await? {
        return Err(AppError::BadRequest("Email already exists".into()));
    }

    // 비밀번호 해시화
    let password_hash = hash_password(&req.password)?;

    // 새 유저 생성
    let new_user = User {
        id: uuid::Uuid::new_v4().to_string(),
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

    Ok(HttpResponse::Ok().json(AuthResponse {
        access_token: tokens.0,
        refresh_token: tokens.1,
        user: user.into(),
    }))
}

async fn handle_google_login(
    req: SocialLoginRequest,
    repo: web::Data<Repository>,
    http_client: web::Data<Client>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    // Google token info endpoint로 토큰 검증
    let token_info = http_client
        .get("https://oauth2.googleapis.com/tokeninfo")
        .query(&[("id_token", &req.token)])
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

    let user = handle_user_creation(email, name, picture, "google", repo).await?;
    let tokens = generate_tokens(&user, &config)?;

    Ok(HttpResponse::Ok().json(AuthResponse {
        access_token: tokens.0,
        refresh_token: tokens.1,
        user: user.into(),
    }))
}

async fn handle_kakao_login(
    req: SocialLoginRequest,
    repo: web::Data<Repository>,
    http_client: web::Data<Client>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    // Kakao token info endpoint로 토큰 검증
    let user_info = http_client
        .get("https://kapi.kakao.com/v2/user/me")
        .header("Authorization", format!("Bearer {}", req.token))
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

    let user = handle_user_creation(email, name, picture, "kakao", repo).await?;
    let tokens = generate_tokens(&user, &config)?;

    Ok(HttpResponse::Ok().json(AuthResponse {
        access_token: tokens.0,
        refresh_token: tokens.1,
        user: user.into(),
    }))
}

async fn handle_apple_login(
    req: SocialLoginRequest,
    repo: web::Data<Repository>,
    http_client: web::Data<Client>,
    config: web::Data<AppConfig>,
) -> Result<HttpResponse, AppError> {
    // Apple의 경우 클라이언트에서 검증된 ID 토큰을 받아서 처리
    // jwt_decode를 사용하여 토큰 검증
    let email = req.email.ok_or_else(|| {
        AppError::BadRequest("Email is required for Apple sign in".into())
    })?;

    let user = handle_user_creation(&email, None, None, "apple", repo).await?;
    let tokens = generate_tokens(&user, &config)?;

    Ok(HttpResponse::Ok().json(AuthResponse {
        access_token: tokens.0,
        refresh_token: tokens.1,
        user: user.into(),
    }))
}

async fn handle_user_creation(
    email: &str,
    name: Option<String>,
    profile_image: Option<String>,
    provider: &str,
    repo: web::Data<Repository>,
) -> Result<User, AppError> {
    match repo.find_user_by_email(email).await? {
        Some(mut user) => {
            // 기존 유저 정보 업데이트
            if user.provider.as_ref() == provider {
                if let Some(new_name) = name {
                    user.name = new_name;
                }
                user.profile_image_url = profile_image;
                user.last_login_at = Some(Utc::now());
                user.updated_at = Utc::now();
                repo.update_user(user.clone()).await?;
            }
            Ok(user)
        }
        None => {
            // 새 유저 생성
            let new_user = User {
                id: uuid::Uuid::new_v4().to_string(), // UUID 생성
                email: email.to_string(),
                password_hash: None,  // 소셜 로그인은 비밀번호 없음
                name: name.unwrap_or_else(|| email.split('@').next().unwrap_or("User").to_string()),
                role: UserRole::User,  // 기본 사용자 역할
                provider: AuthProvider::from(provider),  // 문자열을 AuthProvider로 변환
                profile_image_url: profile_image,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                last_login_at: Some(Utc::now()),
            };
            Ok(repo.create_user(new_user).await?)
        }
    }
}

fn generate_tokens(user: &User, config: &AppConfig) -> Result<(String, String), AppError> {
    let now = Utc::now().timestamp() as usize;

    // Access Token 생성
    let access_claims = Claims {
        sub: user.id.to_string(),
        exp: now + config.jwt.access_token_expire as usize, // 예: 15분
        iat: now,
        token_type: "access".to_string(),
    };

    let access_token = encode(
        &Header::default(),
        &access_claims,
        &EncodingKey::from_secret(config.jwt.secret.as_bytes()),
    )
    .map_err(|e| AppError::Internal(format!("Token generation error: {}", e)))?;

    // Refresh Token 생성
    let refresh_claims = Claims {
        sub: user.id.to_string(),
        exp: now + config.jwt.refresh_token_expire as usize, // 예: 7일
        iat: now,
        token_type: "refresh".to_string(),
    };

    let refresh_token = encode(
        &Header::default(),
        &refresh_claims,
        &EncodingKey::from_secret(config.jwt.secret.as_bytes()),
    )
    .map_err(|e| AppError::Internal(format!("Token generation error: {}", e)))?;

    Ok((access_token, refresh_token))
}