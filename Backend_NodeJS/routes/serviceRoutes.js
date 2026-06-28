import { Route, Router } from "express";
import ServiceController from "../controllers/serviceController.js";
import auth from "../middleware/auth.js";
import adminController from "../controllers/adminController.js";
import adminAuth from "../middleware/admin.js";

const serviceRoutes = Router();

serviceRoutes.post('/create', auth, ServiceController.createService);
serviceRoutes.put('/update/:serviceId', auth, ServiceController.updateService);
serviceRoutes.delete('/delete/:serviceId', auth, ServiceController.deleteService);
serviceRoutes.post("/admin/master-services", adminAuth, adminController.adminCreate);

// Routes dành cho bác sĩ cấu hình hành nghề
serviceRoutes.get("/doctor/available-master", auth, ServiceController.doctorGetMasterList);
serviceRoutes.post("/doctor/choose-service", auth, ServiceController.doctorChooseService);
serviceRoutes.get("/doctor/my-services/:doctorId", auth, ServiceController.doctorGetMyServices);
serviceRoutes.post("/doctor/remove-service", auth, ServiceController.doctorDeleteService);

serviceRoutes.get("/admin/master-services", adminAuth, adminController.adminGetServices);
serviceRoutes.post("/admin/master-services", adminAuth, adminController.adminCreate);
serviceRoutes.put("/admin/master-services/:id", adminAuth, adminController.adminUpdateService);
serviceRoutes.delete("/admin/master-services/:id", adminAuth, adminController.adminDeleteService);

export default serviceRoutes;