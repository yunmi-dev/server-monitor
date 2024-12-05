// src/auth/jwt.rs
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use chrono::Utc;
use crate::error::AppError;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,           // user id
    pub exp: i64,             // expiration time
    pub iat: i64,             // issued at
    pub token_type: String,   // access or refresh
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TokenPair {
    pub access_token: String,
    pub refresh_token: String,
}

#[allow(dead_code)]
const ACCESS_TOKEN_DURATION: i64 = 15 * 60; // 15 minutes in seconds
#[allow(dead_code)]
const REFRESH_TOKEN_DURATION: i64 = 7 * 24 * 3600;

impl Claims {
    pub fn new(user_id: &str, token_type: &str, duration: i64) -> Self {
        let now = Utc::now().timestamp();
        Self {
            sub: user_id.to_string(),
            exp: now + duration,
            iat: now,
            token_type: token_type.to_string(),
        }
    }
}

pub fn create_token_pair(user_id: &str) -> Result<TokenPair, AppError> {
    let secret = get_secret()?;
    let encoding_key = EncodingKey::from_secret(secret.as_bytes());

    let access_claims = Claims::new(user_id, "access", ACCESS_TOKEN_DURATION);
    let refresh_claims = Claims::new(user_id, "refresh", REFRESH_TOKEN_DURATION);

    let access_token = encode(
        &Header::default(),
        &access_claims,
        &encoding_key
    ).map_err(|e| AppError::Internal(format!("Access token creation failed: {}", e)))?;

    let refresh_token = encode(
        &Header::default(),
        &refresh_claims,
        &encoding_key
    ).map_err(|e| AppError::Internal(format!("Refresh token creation failed: {}", e)))?;

    Ok(TokenPair {
        access_token,
        refresh_token,
    })
}

pub fn verify_token(token: &str) -> Result<Claims, AppError> {
    let secret = get_secret()?;
    let decoding_key = DecodingKey::from_secret(secret.as_bytes());
    let validation = Validation::default();
    
    decode::<Claims>(token, &decoding_key, &validation)
        .map(|token_data| token_data.claims)
        .map_err(|e| match e.kind() {
            jsonwebtoken::errors::ErrorKind::ExpiredSignature => {
                AppError::AuthError("Token has expired".to_string())
            }
            jsonwebtoken::errors::ErrorKind::InvalidToken => {
                AppError::AuthError("Invalid token format".to_string())
            }
            _ => AppError::AuthError(format!("Token verification failed: {}", e))
        })
}

#[allow(dead_code)]
pub fn verify_refresh_token(token: &str) -> Result<Claims, AppError> {
    let claims = verify_token(token)?;
    
    if claims.token_type != "refresh" {
        return Err(AppError::AuthError("Invalid token type".to_string()));
    }

    Ok(claims)
}

#[allow(dead_code)]
pub fn refresh_access_token(refresh_token: &str) -> Result<String, AppError> {
    let claims = verify_refresh_token(refresh_token)?;
    let secret = get_secret()?;
    
    let new_claims = Claims::new(&claims.sub, "access", ACCESS_TOKEN_DURATION);

    encode(
        &Header::default(),
        &new_claims,
        &EncodingKey::from_secret(secret.as_bytes())
    ).map_err(|e| AppError::Internal(format!("Access token renewal failed: {}", e)))
}

fn get_secret() -> Result<String, AppError> {
    std::env::var("JWT_SECRET")
        .map_err(|_| AppError::Internal("JWT_SECRET not set".to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;
    use std::thread::sleep;
    use std::time::Duration;

    fn setup() {
        env::set_var("JWT_SECRET", "test_secret");
    }

    #[test]
    fn test_create_and_verify_token_pair() {
        setup();
        let user_id = "test_user";
        
        let token_pair = create_token_pair(user_id).unwrap();
        
        // Verify access token
        let access_claims = verify_token(&token_pair.access_token).unwrap();
        assert_eq!(access_claims.sub, user_id);
        assert_eq!(access_claims.token_type, "access");
        
        // Verify refresh token
        let refresh_claims = verify_token(&token_pair.refresh_token).unwrap();
        assert_eq!(refresh_claims.sub, user_id);
        assert_eq!(refresh_claims.token_type, "refresh");
    }

    #[test]
    fn test_token_expiration() {
        setup();
        let user_id = "test_user";
        
        let claims = Claims::new(user_id, "test", 1); // 1 second expiration
        let token = encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret("test_secret".as_bytes())
        ).unwrap();
        
        sleep(Duration::from_secs(2));
        
        let result = verify_token(&token);
        assert!(result.is_err());
        
        match result {
            Err(AppError::AuthError(msg)) => {
                assert!(msg.contains("expired"));
            }
            _ => panic!("Expected AuthError with expired message"),
        }
    }

    #[test]
    fn test_refresh_token_flow() {
        setup();
        let user_id = "test_user";
        
        let token_pair = create_token_pair(user_id).unwrap();
        let new_access_token = refresh_access_token(&token_pair.refresh_token).unwrap();
        
        let claims = verify_token(&new_access_token).unwrap();
        assert_eq!(claims.sub, user_id);
        assert_eq!(claims.token_type, "access");
    }
}