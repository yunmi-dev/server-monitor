// src/auth/types.rs
use serde::{Deserialize, Serialize};
use crate::db::models::{UserRole, AuthProvider};

#[derive(Debug, Serialize, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub name: String,
}

#[derive(Debug, Deserialize)]
pub struct SocialLoginRequest {
    pub provider: String,
    pub token: String,  // access_token을 token으로 변경 (통일)
    pub email: Option<String>
}


#[derive(Debug, Serialize, Deserialize)]
pub struct AuthResponse {
    pub token: String,
    pub refresh_token: String,
    pub user: UserResponse,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UserResponse {
    pub id: String,
    pub email: String,
    pub name: String,
    pub role: UserRole,
    pub provider: AuthProvider,
    pub profile_image_url: Option<String>,
}

impl From<crate::db::models::User> for UserResponse {
    fn from(user: crate::db::models::User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role,
            provider: user.provider,
            profile_image_url: user.profile_image_url,
        }
    }
}