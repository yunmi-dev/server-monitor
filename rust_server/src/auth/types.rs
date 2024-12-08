// src/auth/types.rs
use serde::{Deserialize, Serialize};
use crate::db::models::{UserRole, AuthProvider};
use actix_web::{FromRequest, HttpRequest, dev::Payload, Error, HttpMessage};
use std::future::{ready, Ready};
use actix_web::error::ErrorUnauthorized;
use crate::auth::jwt::Claims;

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


#[derive(Debug, Clone)]
pub struct AuthenticatedUser {
    pub id: String,
    pub email: String,
    pub role: UserRole,
}

impl From<Claims> for AuthenticatedUser {
    fn from(claims: Claims) -> Self {
        Self {
            id: claims.sub,
            email: claims.email,
            role: claims.role,
        }
    }
}

impl FromRequest for AuthenticatedUser {
    type Error = Error;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(req: &HttpRequest, _: &mut Payload) -> Self::Future {
        ready(
            req.extensions()
                .get::<Claims>()
                .map(|claims| claims.clone().into())
                .ok_or_else(|| ErrorUnauthorized("Authentication required"))
        )
    }
}