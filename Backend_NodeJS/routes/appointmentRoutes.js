import { Router } from 'express';
import appointmentController from '../controllers/appointmentController.js'; 
import auth from '../middleware/auth.js';

const appointmentRoutes = Router();

// Tạo một cụm router dành riêng cho các API cần đăng nhập
const authAppointmentRoutes = Router();
authAppointmentRoutes.use(auth);

// API Lấy danh sách lịch hẹn của bệnh nhân
authAppointmentRoutes.get('/my-list', appointmentController.getMyList);

// API Lấy chi tiết lịch hẹn dựa trên Ma_lich_hen
authAppointmentRoutes.get('/detail/:id', appointmentController.getDetails);

// API Hủy lịch hẹn với điều kiện chặn hủy trước 2 giờ
authAppointmentRoutes.put('/cancel/:id', appointmentController.cancel);

// API Đổi lịch hẹn với điều kiện chặn đổi trước 2 giờ
authAppointmentRoutes.put('/reschedule/:id', appointmentController.reschedule);

// --- KHU VỰC API CỦA BÁC SĨ ---
// API Lấy dữ liệu trang chủ Bác sĩ
authAppointmentRoutes.get('/doctor/dashboard', appointmentController.getDoctorDashboard);

// API Lấy chi tiết 1 ca khám cho Bác sĩ
authAppointmentRoutes.get('/doctor/detail/:id', appointmentController.getDoctorAppointmentDetail);

// API Bác sĩ duyệt/từ chối lịch hẹn (Gửi action: 'confirm' hoặc 'reject' qua body)
authAppointmentRoutes.put('/doctor/status/:id', appointmentController.updateStatus);

// API Lấy tất cả lịch hẹn của bác sĩ (cho màn hình 5 Tabs)
authAppointmentRoutes.get('/doctor/all-list', appointmentController.getAllDoctorList);

// Gộp cụm bảo mật vào route chính
appointmentRoutes.use('/', authAppointmentRoutes);

export default appointmentRoutes;