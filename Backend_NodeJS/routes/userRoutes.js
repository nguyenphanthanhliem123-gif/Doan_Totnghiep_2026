import { Router } from "express";
import userController from "../controllers/userController.js";

const userRoutes = Router();

// API Đăng ký tài khoản bệnh nhân
userRoutes.post('/register', userController.register);

// API Đăng nhập hệ thống
userRoutes.post('/login', userController.login);

export default userRoutes;