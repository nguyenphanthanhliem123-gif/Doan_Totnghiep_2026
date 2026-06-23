import { Router } from "express";
import doctorController from "../controllers/doctorController.js";
import auth from "../middleware/auth.js";

const doctorRoutes = Router();
const authDoctorRoutes = Router();
authDoctorRoutes.use(auth);

// API: Lấy thông tin chi tiết của bác sĩ dựa vào mã bác sĩ (ID)
authDoctorRoutes.post('/update', doctorController.updateProfile);
authDoctorRoutes.get('/detail', doctorController.getDoctorByUserId);
authDoctorRoutes.get('/my-clinics', doctorController.getSelectedClinics);
doctorRoutes.use('/', authDoctorRoutes);


doctorRoutes.get('/', doctorController.getDoctors);
doctorRoutes.get('/:id', doctorController.getDoctorById);

export default doctorRoutes;