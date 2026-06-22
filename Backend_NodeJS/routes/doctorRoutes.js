import { Router } from "express";
import doctorController from "../controllers/doctorController.js";
import auth from "../middleware/auth.js";

const doctorRoutes = Router();
const authDoctorRoutes = Router();
authDoctorRoutes.use(auth);

// API: Lấy thông tin chi tiết của bác sĩ dựa vào mã bác sĩ (ID)
doctorRoutes.get('/:id', doctorController.getDoctorById);
doctorRoutes.get('/', doctorController.getDoctors);
authDoctorRoutes.post('/update', doctorController.updateProfile);


doctorRoutes.use('/', authDoctorRoutes);
export default doctorRoutes;