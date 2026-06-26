import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import { embedController, publicConfigController, chatController, ingestController } from './widget.controller';

const router = Router();

// ── Públicas (llamadas desde el sitio del cliente, CORS abierto) ──────────────
// GET  /api/widget/config?key=ax_xxx → config pública para renderizar el widget
// POST /api/widget/chat              → mensaje del visitante → respuesta de Kairos
router.get ('/config', publicConfigController);
router.post('/chat',   chatController);

// ── Panel (requiere auth) ─────────────────────────────────────────────────────
// GET  /api/widget/embed  → site_key + snippet para instalar el widget
// POST /api/widget/ingest → scrapea el sitio del cliente y autoconfigura Kairos
router.get ('/embed',  authMiddleware, embedController);
router.post('/ingest', authMiddleware, ingestController);

export default router;
