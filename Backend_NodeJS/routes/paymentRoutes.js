import { Router } from "express";
import paymentController from "../controllers/paymentController.js";
import auth from "../middleware/auth.js";

const paymentRoute = Router();
const authPaymentRoute = Router();
authPaymentRoute.use(auth);

authPaymentRoute.get('/history', paymentController.getPaymentHistory);

paymentRoute.use('/', authPaymentRoute);
export default paymentRoute;