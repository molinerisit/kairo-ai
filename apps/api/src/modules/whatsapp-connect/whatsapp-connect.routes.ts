import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import {
  connectController,
  statusController,
  disconnectController,
} from './whatsapp-connect.controller';

const router = Router();

router.use(authMiddleware);

// POST   /api/whatsapp/connect    → inicia la conexión con el code del Embedded Signup
// GET    /api/whatsapp/connection → estado de la conexión del tenant
// DELETE /api/whatsapp/connection → desconectar número
router.post  ('/connect',    connectController);
router.get   ('/connection', statusController);
router.delete('/connection', disconnectController);

export default router;
