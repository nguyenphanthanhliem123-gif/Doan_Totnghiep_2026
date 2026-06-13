import { Router } from "express";
import clinicController from "../controllers/clinicController.js";

const clinicRoutes = Router();
clinicRoutes.get('/:id', clinicController.getClinicById);

export default clinicRoutes;