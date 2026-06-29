import { Router } from "express";
import chatbotController from "../controllers/chatbotController.js";

const chatbotRoutes = Router();

// API nhận câu hỏi thông thường (Task M9.6)
chatbotRoutes.post('/ask', chatbotController.askQuestion);

export default chatbotRoutes;