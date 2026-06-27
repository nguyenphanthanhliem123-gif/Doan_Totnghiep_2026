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
<<<<<<< HEAD
adminRoutes.get('/users', adminAuth, adminController.getAllUser);
adminRoutes.post('/lock-account', adminAuth, adminController.lockAccount);
adminRoutes.post('/unlock-account', adminAuth, adminController.unLockAccount);
adminRoutes.get('/user-appointment/:id', adminAuth, adminController.getAppointmentListByUserId);
adminRoutes.get('/user-appointment-detail/:id', adminAuth, adminController.getDetails);
=======

// Lấy toàn bộ danh sách bác sĩ đợi duyệt
adminRoutes.get('/pending-doctors', adminAuth, adminController.getPendingDoctorsList);

// Duyệt kích hoạt bác sĩ
adminRoutes.post('/approve-doctor', adminAuth, adminController.approveDoctor);

// Từ chối bác sĩ kèm lý do
adminRoutes.post('/reject-doctor', adminAuth, adminController.rejectDoctor);

>>>>>>> 4916d8539f33218354ad3674bac4f8f2597deb87
export default adminRoutes;