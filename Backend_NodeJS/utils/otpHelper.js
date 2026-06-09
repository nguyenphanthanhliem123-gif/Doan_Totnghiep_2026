import crypto from 'crypto';
// Tạo một kho lưu trữ trên RAM (In-Memory Storage)
// Map này sẽ lưu dữ liệu với cấu trúc: { 'email@gmail.com': { otp: '123456', userData: {...}, expiresAt: time } }
export const otpStorage = new Map();

// Hàm random 6 số
export const generateOTP = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

// Kho chứa Token Reset Mật Khẩu
// Cấu trúc: { 'abc@gmail.com': { token: 'chuoi_dai_ngoang', expiresAt: time } }
export const resetStorage = new Map();

// 2. Hàm sinh chuỗi Token bảo mật (Ví dụ: 'a1b2c3d4e5f6...')
export const generateResetToken = () => {
    return crypto.randomBytes(32).toString('hex');
};