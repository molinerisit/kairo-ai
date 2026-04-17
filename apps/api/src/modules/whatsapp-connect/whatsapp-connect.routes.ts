import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import {
  accountsController,
  connectController,
  statusController,
  disconnectController,
} from './whatsapp-connect.controller';

const router = Router();

// POST /api/whatsapp/accounts    → recibe code, devuelve { accounts, session_id }
// POST /api/whatsapp/connect     → recibe { session_id, waba_id, phone_number_id }
// GET  /api/whatsapp/connection  → estado actual del tenant
// DELETE /api/whatsapp/connection → desconectar
router.post  ('/accounts',   accountsController);
router.post  ('/connect',    authMiddleware, connectController);
router.get   ('/connection', authMiddleware, statusController);
router.delete('/connection', authMiddleware, disconnectController);

export default router;
