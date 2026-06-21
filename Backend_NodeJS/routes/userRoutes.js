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
// 1. Nhận email và gửi mã OTP
userRoutes.post('/forgot-password', userController.forgotPassword);

// 2. Kiểm tra trước mã OTP
userRoutes.post('/verify-reset-otp', userController.verifyResetOTP);

// 3. Nhận Email, mã OTP và mật khẩu mới từ App gửi lên
userRoutes.post('/update-password', userController.updatePassword);

// API Đăng nhập bằng Google / Facebook
userRoutes.post('/oauth-login', userController.oauthLogin);

// Thêm API Đổi mật khẩu vào nhóm cần bảo mật
authUserRoutes.post('/change-password', userController.changePassword);

// Thêm API Xóa tài khoản vào nhóm cần bảo mật
authUserRoutes.post('/delete-account', userController.deleteAccount);


userRoutes.use('/', authUserRoutes);

export default userRoutes;