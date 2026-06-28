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

// Gọi trực tiếp hàm getDashboard từ adminController
adminRoutes.get('/dashboard', adminAuth, adminController.getDashboard);

// Lấy toàn bộ danh sách bác sĩ đợi duyệt
adminRoutes.get('/pending-doctors', adminAuth, adminController.getPendingDoctorsList);

// Duyệt kích hoạt bác sĩ
adminRoutes.post('/approve-doctor', adminAuth, adminController.approveDoctor);

// Từ chối bác sĩ kèm lý do
adminRoutes.post('/reject-doctor', adminAuth, adminController.rejectDoctor);

// ==========================================
// QUẢN LÝ CHUYÊN KHOA (CRUD)
// ==========================================
adminRoutes.get('/specialties', adminAuth, adminController.getAllSpecialties);
adminRoutes.post('/specialties', adminAuth, adminController.createSpecialty);
adminRoutes.put('/specialties/:id', adminAuth, adminController.updateSpecialty);
adminRoutes.patch('/specialties/:id/toggle', adminAuth, adminController.toggleSpecialtyStatus);

export default adminRoutes;