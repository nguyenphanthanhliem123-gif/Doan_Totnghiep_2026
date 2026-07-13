import { Router } from "express";
import NotificationController from "../controllers/notificationController.js";
import auth from "../middleware/auth.js";

const notificationRoute = Router();
const authNotificationRoute = Router();
authNotificationRoute.use(auth);

authNotificationRoute.get('/', NotificationController.getAllNotification);
authNotificationRoute.get('/count-unread', NotificationController.getNotificationUnRead);
authNotificationRoute.put('/read/:notificationID', NotificationController.updateStatus);
authNotificationRoute.put('/save-FCMToken', NotificationController.saveFCMToken);

notificationRoute.use('/', authNotificationRoute);
export default notificationRoute;