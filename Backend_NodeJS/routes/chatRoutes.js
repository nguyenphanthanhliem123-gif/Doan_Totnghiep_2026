import { Router } from 'express';
import ChatController from '../controllers/chatController.js';

const chatRoutes = Router();

chatRoutes.post('/', ChatController.handleChat);

export default chatRoutes;
