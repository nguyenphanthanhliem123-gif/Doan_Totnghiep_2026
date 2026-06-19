import { Router } from "express";
import paymentController from "../controllers/paymentController.js";
import auth from "../middleware/auth.js";

const paymentRoute = Router();
const authPaymentRoute = Router();
authPaymentRoute.use(auth);

authPaymentRoute.get('/history', paymentController.getPaymentHistory);

paymentRoute.post('/create-vnpay-url', paymentController.createVNPayUrl);

// Route VNPay sẽ tự động gọi (redirect) về sau khi khách thanh toán xong trên web
paymentRoute.get('/vnpay-return', paymentController.vnpayReturn);

paymentRoute.use('/', authPaymentRoute);
export default paymentRoute;