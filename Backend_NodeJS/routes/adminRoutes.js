import { Router } from "express";
const adminRoutes = Router();

import userController from "../controllers/userController.js";
import auth from "../middleware/auth.js";
import admin from "../middleware/admin.js";
import profileController from "../controllers/profileController.js";

const adminAuthRoutes = Router();
adminAuthRoutes.use(auth,admin);

adminAuthRoutes.get('/profiles', profileController.getAll);

adminRoutes.use('/', adminAuthRoutes);
export default adminRoutes;