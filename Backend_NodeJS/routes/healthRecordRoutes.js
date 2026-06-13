import { Router } from "express";
import auth from "../middleware/auth.js";
import healthRecordController from "../controllers/healthRecordController.js";

const healthRecordRoutes = Router();

const authHealthRecordRoutes = Router();
authHealthRecordRoutes.use(auth);

//Routes
authHealthRecordRoutes.get('/', healthRecordController.getAllHealthRecordByUserID);
authHealthRecordRoutes.post('/add',healthRecordController.addRelativeProfile);
authHealthRecordRoutes.put('/update', healthRecordController.updateHealthRecord);
authHealthRecordRoutes.get('/detail/:id', healthRecordController.getHealthRecordDetail);

healthRecordRoutes.use('/', authHealthRecordRoutes);
export default healthRecordRoutes;