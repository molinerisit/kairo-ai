import { Router } from 'express';
import { verifyWebhook, receiveWebhook } from './whatsapp.controller';
import { simulateController } from './simulate.controller';
import { evolutionWebhookController } from './evolution.controller';
import { authMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();

// GET  /api/webhook/whatsapp → verificación inicial de Meta (legacy)
// POST /api/webhook/whatsapp → mensajes entrantes Meta (legacy)
router.get ('/whatsapp', verifyWebhook);
router.post('/whatsapp', receiveWebhook);

// POST /api/webhook/evolution → eventos de Evolution API (todas las instancias)
// No requiere JWT — Evolution API se autentica con su propia API key en el header
router.post('/evolution', evolutionWebhookController);

// POST /api/webhook/simulate → simulador de mensajes entrantes (solo para testing)
router.post('/simulate', authMiddleware, simulateController);

export default router;
