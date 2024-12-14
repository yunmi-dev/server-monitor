use rust_server::{
    config::{ServerConfig, AuthConfig},
    db::models::{User, UserRole, AuthProvider},
};
use uuid::Uuid;
use chrono::Utc;

pub fn create_test_user() -> User {
    User {
        id: Uuid::new_v4().to_string(),
        email: "test@example.com".to_string(),
        password_hash: Some("$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyNiLR/2ARoxtq".to_string()),
        name: "Test User".to_string(),
        role: UserRole::User,
        provider: AuthProvider::Email,
        profile_image_url: None,
        created_at: Utc::now(),
        updated_at: Utc::now(),
        last_login_at: Some(Utc::now()),
    }
}

pub fn create_test_config() -> ServerConfig {
    let mut config = ServerConfig::with_defaults();
    config.auth = AuthConfig {
        jwt_secret: "test_secret".to_string(),
        access_token_expire: 3600,
        refresh_token_expire: 86400,
        token_expiration_hours: 24,
    };
    config
}