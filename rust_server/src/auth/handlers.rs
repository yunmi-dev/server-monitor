use actix_web::{post, web, HttpResponse};
use chrono::Utc;
use jsonwebtoken::{encode, EncodingKey, Header};
use reqwest::Client;
use uuid::Uuid;
use serde::{Serialize, Deserialize};
use crate::auth::utils::verify_password;
use crate::auth::types::{AuthResponse, RegisterRequest, SocialLoginRequest, UserResponse};
use crate::auth::jwt::Claims;
use crate::auth::utils::hash_password;
use crate::config::ServerConfig;
use crate::db::models::{User, UserRole, AuthProvider};
use crate::db::repository::Repository;
use crate::error::AppError;
use serde_json::json;

#[derive(Debug, Serialize, Deserialize)]
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

#[post("/social-login")]
pub async fn social_login(
    req: web::Json<SocialLoginRequest>,
    repo: web::Data<Repository>,
    _http_client: web::Data<Client>,
    config: web::Data<ServerConfig>,
) -> Result<HttpResponse, AppError> {
    // 모든 소셜 로그인에 대해 동일한 처리
    let email = "test@example.com";
    let name = Some("Test User".to_string());
    let provider = match req.provider.as_str() {
        "facebook" => AuthProvider::Facebook,
        "google" => AuthProvider::Google,
        "kakao" => AuthProvider::Kakao,
        "apple" => AuthProvider::Apple,
        _ => return Err(AppError::BadRequest("Unsupported provider".into())),
    };

    let user = handle_user_creation(email, name, None, provider, repo).await?;
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
