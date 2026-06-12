import crypto from 'crypto';

// 1. Lấy khóa bí mật từ .env (Bây giờ bạn nhập chuỗi dài ngắn bao nhiêu cũng được)
const SECRET_STRING = process.env.AES_KEY || 'auth_secret_key_bat_ky!!'; 

// 2. Dùng SHA-256 để ép chuỗi trên thành 1 Buffer chính xác 32 bytes
const ENCRYPTION_KEY = crypto.createHash('sha256').update(String(SECRET_STRING)).digest(); 

const IV_LENGTH = 16; 

// Hàm mã hóa
export function encrypt(text) {
    if (!text) return null;
    const iv = crypto.randomBytes(IV_LENGTH);
    
    // Lưu ý: Nhét thẳng biến ENCRYPTION_KEY vào, không cần Buffer.from() nữa
    const cipher = crypto.createCipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
    
    let encrypted = cipher.update(text);
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    return iv.toString('hex') + ':' + encrypted.toString('hex');
}

// Hàm giải mã
export function decrypt(text) {
    if (!text) return null;
    try {
        const textParts = text.split(':');
        const iv = Buffer.from(textParts.shift(), 'hex');
        const encryptedText = Buffer.from(textParts.join(':'), 'hex');
        
        // Nhét thẳng biến ENCRYPTION_KEY vào đây
        const decipher = crypto.createDecipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
        
        let decrypted = decipher.update(encryptedText);
        decrypted = Buffer.concat([decrypted, decipher.final()]);
        return decrypted.toString();
    } catch (error) {
        return "Lỗi giải mã dữ liệu";
    }
}