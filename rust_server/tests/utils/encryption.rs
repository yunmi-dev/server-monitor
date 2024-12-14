// tests/utils/encryption.rs
use rust_server::utils::encryption::Encryptor;
use base64::{engine::general_purpose::STANDARD as base64, Engine};

#[test]
fn test_encryptor_initialization() {
    // Generate valid key and nonce
    let key = Encryptor::generate_key();
    let nonce = Encryptor::generate_nonce();
    
    // Test successful initialization
    let encryptor = Encryptor::new(&key, &nonce);
    assert!(encryptor.is_ok());
    
    // Test invalid key
    let invalid_key = "invalid_key";
    let result = Encryptor::new(invalid_key, &nonce);
    assert!(result.is_err());
    
    // Test invalid nonce
    let invalid_nonce = "invalid_nonce";
    let result = Encryptor::new(&key, invalid_nonce);
    assert!(result.is_err());
}

#[test]
fn test_key_generation() {
    let key = Encryptor::generate_key();
    
    // Key should be base64 encoded
    let decoded = base64.decode(key);
    assert!(decoded.is_ok());
    
    // Key should be 32 bytes (256 bits)
    assert_eq!(decoded.unwrap().len(), 32);
}

#[test]
fn test_nonce_generation() {
    let nonce = Encryptor::generate_nonce();
    
    // Nonce should be base64 encoded
    let decoded = base64.decode(nonce);
    assert!(decoded.is_ok());
    
    // Nonce should be 12 bytes
    assert_eq!(decoded.unwrap().len(), 12);
}

#[test]
fn test_encryption_decryption() {
    let key = Encryptor::generate_key();
    let nonce = Encryptor::generate_nonce();
    let encryptor = Encryptor::new(&key, &nonce).unwrap();
    
    let original_text = "Hello, World!";
    
    // Test encryption
    let encrypted = encryptor.encrypt(original_text);
    assert!(encrypted.is_ok());
    let encrypted_text = encrypted.unwrap();
    
    // Encrypted text should be different from original
    assert_ne!(encrypted_text, original_text);
    
    // Test decryption
    let decrypted = encryptor.decrypt(&encrypted_text);
    assert!(decrypted.is_ok());
    assert_eq!(decrypted.unwrap(), original_text);
}

#[test]
fn test_decryption_with_invalid_data() {
    let key = Encryptor::generate_key();
    let nonce = Encryptor::generate_nonce();
    let encryptor = Encryptor::new(&key, &nonce).unwrap();
    
    // Test with invalid base64
    let result = encryptor.decrypt("invalid-base64-data");
    assert!(result.is_err());
    
    // Test with valid base64 but invalid ciphertext
    let invalid_data = base64.encode("invalid data");
    let result = encryptor.decrypt(&invalid_data);
    assert!(result.is_err());
}

#[test]
fn test_different_encryptors() {
    // Create two different encryptors
    let key1 = Encryptor::generate_key();
    let nonce1 = Encryptor::generate_nonce();
    let encryptor1 = Encryptor::new(&key1, &nonce1).unwrap();
    
    let key2 = Encryptor::generate_key();
    let nonce2 = Encryptor::generate_nonce();
    let encryptor2 = Encryptor::new(&key2, &nonce2).unwrap();
    
    let text = "Test message";
    
    // Encrypt with first encryptor
    let encrypted = encryptor1.encrypt(text).unwrap();
    
    // Try to decrypt with second encryptor
    let result = encryptor2.decrypt(&encrypted);
    assert!(result.is_err());
}

#[test]
fn test_encryption_with_special_characters() {
    let key = Encryptor::generate_key();
    let nonce = Encryptor::generate_nonce();
    let encryptor = Encryptor::new(&key, &nonce).unwrap();
    
    let special_text = "Hello, 世界! 🌍 @#$%^&*";
    
    let encrypted = encryptor.encrypt(special_text).unwrap();
    let decrypted = encryptor.decrypt(&encrypted).unwrap();
    
    assert_eq!(decrypted, special_text);
}