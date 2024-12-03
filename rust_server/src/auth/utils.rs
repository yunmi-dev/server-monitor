// src/auth/utils.rs
use bcrypt::{hash, DEFAULT_COST};
use crate::error::AppError;

pub fn hash_password(password: &str) -> Result<String, AppError> {
    hash(password, DEFAULT_COST)
        .map_err(|e| AppError::Internal(format!("Password hashing failed: {}", e)))
}