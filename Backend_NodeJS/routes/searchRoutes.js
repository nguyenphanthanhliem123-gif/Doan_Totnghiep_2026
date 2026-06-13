import { Router } from "express";
import searchController from "../controllers/searchController.js";

const searchRoutes = Router();

searchRoutes.get('/global-search', searchController.searchAll);

export default searchRoutes;