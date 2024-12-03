// src/auth/mod.rs
pub mod handlers;
mod jwt;
mod middleware;
mod types;
mod utils;

pub use crate::error::AppError as AuthError;
pub use jwt::{verify_token, create_token_pair, TokenPair, Claims};  // create_token을 create_token_pair로 변경
pub use middleware::AuthMiddleware;
pub use types::*;

// Re-export utils for use in other modules
pub use utils::hash_password;