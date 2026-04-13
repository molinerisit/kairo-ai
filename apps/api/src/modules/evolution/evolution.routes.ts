import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import { connectController, statusController, disconnectController } from './evolution.controller';

const router = Router();
router.use(authMiddleware);

// POST   /api/evolution/connect    → inicia vinculación, devuelve QR base64
// GET    /api/evolution/status     → estado de la instancia + número
// DELETE /api/evolution/disconnect → desconecta el número
router.post  ('/connect',    connectController);
router.get   ('/status',     statusController);
router.delete('/disconnect', disconnectController);

export default router;
