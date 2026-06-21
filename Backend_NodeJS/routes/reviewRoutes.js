import { Router } from "express";
import reviewController from "../controllers/reviewController.js";
import auth from "../middleware/auth.js";

const reviewRoutes = Router();
const authReviewRoutes = Router();
authReviewRoutes.use(auth);

// API lấy danh sách đánh giá của bác sĩ theo Ma_bac_si
reviewRoutes.get('/doctor/:doctorId', reviewController.getReviewsByDoctorId);

authReviewRoutes.post('/create', reviewController.createReview);

reviewRoutes.use('/', authReviewRoutes);
export default reviewRoutes;