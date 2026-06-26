import { Router } from "express";
import adminController from "../controllers/adminController.js";

const adminRoutes = Router();

adminRoutes.post('/login', adminController.login);
adminRoutes.post('/verify-otp', adminController.verifyOtp);

export default adminRoutes;