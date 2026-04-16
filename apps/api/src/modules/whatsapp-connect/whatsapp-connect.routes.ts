import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import {
  accountsController,
  connectController,
  statusController,
  disconnectController,
} from './whatsapp-connect.controller';

const router = Router();

// GET  /api/whatsapp/accounts?access_token=xxx  → lista WABAs y números (no requiere JWT, sí token de Meta)
// POST /api/whatsapp/connect                    → guarda la conexión elegida
// GET  /api/whatsapp/connection                 → estado actual
// DELETE /api/whatsapp/connection               → desconectar
router.get   ('/accounts',   accountsController);
router.post  ('/connect',    authMiddleware, connectController);
router.get   ('/connection', authMiddleware, statusController);
router.delete('/connection', authMiddleware, disconnectController);

export default router;
