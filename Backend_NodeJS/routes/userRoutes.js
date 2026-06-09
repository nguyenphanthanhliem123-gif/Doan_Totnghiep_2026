import { Router } from "express";
import userController from "../controllers/userController.js";

const userRoutes = Router();

// API gửi thông tin đăng ký để nhận mã OTP qua Email
userRoutes.post('/register', userController.register);

// API gửi mã OTP lên để xác thực và lưu chính thức vào Database
userRoutes.post('/verify-otp', userController.verifyOTPAndRegister);

// API đăng nhập hệ thống
userRoutes.post('/login', userController.login);

// ==================================
// API QUÊN MẬT KHẨU
// ==================================
// 1. Nhận email và gửi link reset
userRoutes.post('/forgot-password', userController.forgotPassword);

// 2. Mở giao diện HTML khi người dùng click vào link trong email (phải dùng GET)
userRoutes.get('/reset-password-page', userController.renderResetPasswordPage);

// 3. Nhận mật khẩu mới từ form HTML gửi lên (dùng POST)
userRoutes.post('/update-password', userController.updatePassword);

export default userRoutes;