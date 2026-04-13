import { Router } from 'express';
import { verifyWebhook, receiveWebhook } from './whatsapp.controller';
import { simulateController } from './simulate.controller';
import { authMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();

// GET  /api/webhook/whatsapp → verificación inicial de Meta
// POST /api/webhook/whatsapp → mensajes entrantes
router.get ('/whatsapp', verifyWebhook);
router.post('/whatsapp', receiveWebhook);

// POST /api/webhook/simulate → simulador de mensajes entrantes (solo para testing)
// Requiere JWT — usa el tenant del usuario autenticado
router.post('/simulate', authMiddleware, simulateController);

export default router;
