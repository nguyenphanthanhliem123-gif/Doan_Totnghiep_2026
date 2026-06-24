import { Router } from "express";
import doctorController from "../controllers/doctorController.js";
import auth from "../middleware/auth.js";
import clinicController from "../controllers/clinicController.js";
import ScheduleController from "../controllers/scheduleController.js";

const doctorRoutes = Router();

// ==========================================
// 1. CÁC API KHÔNG CẦN TOKEN (PUBLIC)
// ==========================================
doctorRoutes.get('/', doctorController.getDoctors);

// ==========================================
// 2. CÁC API CẦN XÁC THỰC TOKEN (PROTECTED)
// ==========================================
doctorRoutes.post('/update', auth, doctorController.updateProfile);
doctorRoutes.get('/detail', auth, doctorController.getDoctorByUserId);
doctorRoutes.get('/my-clinics', auth, doctorController.getSelectedClinics);
doctorRoutes.post('/update-clinics', auth, clinicController.updateDoctorClinics);
doctorRoutes.post('/schedule/config/create', auth, ScheduleController.updateScheduleConfig);
doctorRoutes.get('/schedule/config', auth, ScheduleController.getScheduleConfig);
doctorRoutes.post('/schedule/slots/generate', auth, ScheduleController.generateDoctorSlots);

// ==========================================
// 3. API CÓ CHỨA BIẾN (:id) - BẮT BUỘC PHẢI ĐỂ CÙNG
// ==========================================
// API này không cần token
doctorRoutes.get('/:id', doctorController.getDoctorById);

export default doctorRoutes;