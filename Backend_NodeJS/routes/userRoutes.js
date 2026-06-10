import { Router } from "express";
import userController from "../controllers/userController.js";
import auth from "../middleware/auth.js";

const userRoutes = Router();

const authUserRoutes = Router();
authUserRoutes.use(auth);

// API gửi thông tin đăng ký để nhận mã OTP qua Email
userRoutes.post('/register', userController.register);

// API gửi mã OTP lên để xác thực và lưu chính thức vào Database
userRoutes.post('/verify-otp', userController.verifyOTPAndRegister);

// API đăng nhập hệ thống
userRoutes.post('/login', userController.login);

// API quên mật khẩu
// 1. Nhận email và gửi link reset
userRoutes.post('/forgot-password', userController.forgotPassword);

// 2. Mở giao diện HTML khi người dùng click vào link trong email (phải dùng GET)
userRoutes.get('/reset-password-page', userController.renderResetPasswordPage);

// 3. Nhận mật khẩu mới từ form HTML gửi lên (dùng POST)
userRoutes.post('/update-password', userController.updatePassword);

// API Đăng nhập bằng Google / Facebook
userRoutes.post('/oauth-login', userController.oauthLogin);

authUserRoutes.post('/change-password', userController.changePassword);


userRoutes.use('/',authUserRoutes);

export default userRoutes;