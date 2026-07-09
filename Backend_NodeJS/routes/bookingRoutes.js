import { Router } from "express";
import bookingController from "../controllers/bookingController.js";
import paymentController from "../controllers/paymentController.js";

const bookingRoutes = Router();
bookingRoutes.get('/available-dates/:doctorId', bookingController.getAvailableDates);
bookingRoutes.get('/available-dates', bookingController.getDoctorSchedule);
bookingRoutes.get('/doctor-schedule', bookingController.getDoctorSchedule);
bookingRoutes.post('/', bookingController.createBooking);
bookingRoutes.post('/cancel-unpaid', bookingController.cancelUnpaidBooking);
bookingRoutes.get('/check-status/:bookingId', paymentController.checkPaymentStatus);

export default bookingRoutes;