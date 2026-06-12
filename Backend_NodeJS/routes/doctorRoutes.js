import { Router } from "express";
import doctorController from "../controllers/doctorController.js";

const doctorRoutes = Router();

// API: Lấy thông tin chi tiết của bác sĩ dựa vào mã bác sĩ (ID)
doctorRoutes.get('/:id', doctorController.getDoctorById);

export default doctorRoutes;