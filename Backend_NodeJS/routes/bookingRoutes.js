import { Router } from "express";
import bookingController from "../controllers/bookingController.js";
import paymentController from "../controllers/paymentController.js";
import auth from "../middleware/auth.js";

const bookingRoutes = Router();
bookingRoutes.get('/available-dates/:doctorId', bookingController.getAvailableDates);
bookingRoutes.get('/available-dates', bookingController.getDoctorSchedule);
bookingRoutes.get('/doctor-schedule', bookingController.getDoctorSchedule);
bookingRoutes.post('/', auth, bookingController.createBooking);
bookingRoutes.get('/today-count', auth, bookingController.getTodayCount);
bookingRoutes.post('/cancel-unpaid', bookingController.cancelUnpaidBooking);
bookingRoutes.post('/cancel-combined-unpaid', bookingController.cancelCombinedUnpaidBooking);
bookingRoutes.get('/check-combined-status/:bookingCode', bookingController.checkCombinedPaymentStatus);
bookingRoutes.get('/check-status/:bookingId', paymentController.checkPaymentStatus);

export default bookingRoutes;