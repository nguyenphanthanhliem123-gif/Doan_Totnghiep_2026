import { Router } from "express";
import bookingController from "../controllers/bookingController.js";

const bookingRoutes = Router();
bookingRoutes.get('/available-dates/:doctorId', bookingController.getAvailableDates);
bookingRoutes.get('/available-dates', bookingController.getDoctorSchedule);
bookingRoutes.post('/', bookingController.createBooking);
bookingRoutes.post('/cancel-unpaid', bookingController.cancelUnpaidBooking);

export default bookingRoutes;