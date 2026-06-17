import { Router } from 'express';
import appointmentController from '../controllers/appointmentController.js'; 
import auth from '../middleware/auth.js';

const appointmentRoutes = Router();

// Tạo một cụm router dành riêng cho các API cần đăng nhập
const authAppointmentRoutes = Router();
authAppointmentRoutes.use(auth); // Gắn chốt bảo vệ vào đây

// API Lấy danh sách lịch hẹn của bệnh nhân
authAppointmentRoutes.get('/my-list', appointmentController.getMyList);

// Gộp cụm bảo mật vào route chính
appointmentRoutes.use('/', authAppointmentRoutes);

export default appointmentRoutes;