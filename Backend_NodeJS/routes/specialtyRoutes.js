import { Router } from "express";
import specialtyController from "../controllers/specialtyController.js";

const specialtyRoutes = Router();

specialtyRoutes.get('/', specialtyController.getAllSpecialty);

export default specialtyRoutes;