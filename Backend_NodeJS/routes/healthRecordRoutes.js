import { Router } from "express";
import auth from "../middleware/auth.js";
import healthRecordController from "../controllers/healthRecordController.js";

const healthRecordRoutes = Router();

const authHealthRecordRoutes = Router();
authHealthRecordRoutes.use(auth);

//Routes
authHealthRecordRoutes.get('/', healthRecordController.getAllHealthRecordByUserID);
authHealthRecordRoutes.post('/add',healthRecordController.addRelativeProfile);

healthRecordRoutes.use('/', authHealthRecordRoutes);
export default healthRecordRoutes;