import { Router } from "express";
import profileController from "../controllers/profileController.js";
import auth from "../middleware/auth.js";

const profileRoutes = Router();


const authProfileRoutes = Router();
authProfileRoutes.use(auth);

profileRoutes.post('/upload-avatar', auth, profileController.uploadAvatar);

authProfileRoutes.get('/:Ma_nguoi_dung', profileController.getProfileByMaNguoiDung);
authProfileRoutes.post('/update-profile', profileController.updateProfile);
authProfileRoutes.post('/report', profileController.createReport);


profileRoutes.use('/', authProfileRoutes);
export default profileRoutes;