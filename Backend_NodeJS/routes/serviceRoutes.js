import { Route, Router } from "express";
import ServiceController from "../controllers/serviceController.js";
import auth from "../middleware/auth.js";

const serviceRoutes = Router();

serviceRoutes.post('/create', auth, ServiceController.createService);
serviceRoutes.put('/update/:serviceId', auth, ServiceController.updateService);
serviceRoutes.delete('/delete/:serviceId', auth, ServiceController.deleteService);

export default serviceRoutes;