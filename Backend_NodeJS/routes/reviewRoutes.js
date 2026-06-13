import { Router } from "express";
import reviewController from "../controllers/reviewController.js";

const reviewRoutes = Router();

// API lấy danh sách đánh giá của bác sĩ theo Ma_bac_si
reviewRoutes.get('/doctor/:doctorId', reviewController.getReviewsByDoctorId);

export default reviewRoutes;