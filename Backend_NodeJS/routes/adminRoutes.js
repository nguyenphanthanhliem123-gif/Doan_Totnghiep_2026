import { Router } from "express";
import adminController from "../controllers/adminController.js";
import adminAuth from "../middleware/admin.js";

const adminRoutes = Router();

// ==========================================
// 1. CÁC ROUTE CÔNG KHAI (Không cần Token)
// ==========================================
adminRoutes.post('/login', adminController.login);
adminRoutes.post('/verify-otp', adminController.verifyOtp);

// ==========================================
// 2. CÁC ROUTE BẢO MẬT (Bắt buộc có Token Admin)
// ==========================================

// Gắn adminAuth vào trước hàm xử lý để bảo vệ route
// Gọi trực tiếp hàm getDashboard từ adminController
adminRoutes.get('/dashboard', adminAuth, adminController.getDashboard);

export default adminRoutes;