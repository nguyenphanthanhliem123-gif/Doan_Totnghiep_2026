import { Router } from "express";
import bookingController from "../controllers/bookingController.js";

const bookingRoutes = Router();
bookingRoutes.get('/available-dates/:doctorId', bookingController.getAvailableDates);
bookingRoutes.post('/', bookingController.createBooking);

export default bookingRoutes;