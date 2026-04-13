import { Router } from 'express';
import { verifyWebhook, receiveWebhook } from './whatsapp.controller';

const router = Router();

// GET  /api/webhook/whatsapp → verificación inicial de Meta
// POST /api/webhook/whatsapp → mensajes entrantes
router.get ('/whatsapp', verifyWebhook);
router.post('/whatsapp', receiveWebhook);

export default router;
