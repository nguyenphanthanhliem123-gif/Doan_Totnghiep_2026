import { Router } from "express";
import profileController from "../controllers/profileController.js";
import auth from "../middleware/auth.js";

const profileRoutes = Router();


const authProfileRoutes = Router();
authProfileRoutes.use(auth);

authProfileRoutes.get('/:Ma_nguoi_dung', profileController.getProfileByMaNguoiDung);

profileRoutes.use('/', authProfileRoutes);
export default profileRoutes;