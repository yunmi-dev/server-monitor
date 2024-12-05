// src/utils/encryption.rs
use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm,
};
use base64::{engine::general_purpose::STANDARD as base64, Engine};
use rand::{thread_rng, RngCore}; // RngCore 추가
use crate::error::AppError;

pub struct Encryptor {
    cipher: Aes256Gcm,
    nonce: [u8; 12],
}

impl Encryptor {
    pub fn new(key: &str, nonce: &str) -> Result<Self, AppError> {
        let key_bytes = base64.decode(key)
            .map_err(|_| AppError::Internal("Invalid encryption key format".into()))?;
        
        let nonce_bytes = base64.decode(nonce)
            .map_err(|_| AppError::Internal("Invalid nonce format".into()))?;
        
        if nonce_bytes.len() != 12 {
            return Err(AppError::Internal("Invalid nonce length".into()));
        }
        
        let mut nonce_array = [0u8; 12];
        nonce_array.copy_from_slice(&nonce_bytes);

        let cipher = Aes256Gcm::new_from_slice(&key_bytes)
            .map_err(|_| AppError::Internal("Invalid key length".into()))?;

        Ok(Self { 
            cipher,
            nonce: nonce_array,
        })
    }

    pub fn encrypt(&self, data: &str) -> Result<String, AppError> {
        let ciphertext = self.cipher
            .encrypt(&self.nonce.into(), data.as_bytes())
            .map_err(|_| AppError::Internal("Encryption failed".into()))?;

        Ok(base64.encode(ciphertext))
    }

    pub fn decrypt(&self, encrypted_data: &str) -> Result<String, AppError> {
        let ciphertext = base64.decode(encrypted_data)
            .map_err(|_| AppError::Internal("Invalid encrypted data format".into()))?;

        let plaintext = self.cipher
            .decrypt(&self.nonce.into(), ciphertext.as_ref())
            .map_err(|_| AppError::Internal("Decryption failed".into()))?;

        String::from_utf8(plaintext)
            .map_err(|_| AppError::Internal("Invalid UTF-8 in decrypted data".into()))
    }

    pub fn generate_key() -> String {
        let key = Aes256Gcm::generate_key(thread_rng()); // &제거
        base64.encode(key)
    }

    pub fn generate_nonce() -> String {
        let mut nonce = [0u8; 12];
        thread_rng().fill_bytes(&mut nonce); // RngCore trait의 fill_bytes 메서드 사용
        base64.encode(nonce)
    }
}