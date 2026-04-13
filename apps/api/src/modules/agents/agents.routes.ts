import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import { invokeAgentController } from './agents.controller';

const router = Router();
router.use(authMiddleware);

// POST /api/conversations/:conversationId/agent
// Envía un mensaje del usuario al agente secretario y devuelve la respuesta IA.
// El mensaje se guarda en messages con role='user', la respuesta con role='assistant'.
router.post('/conversations/:conversationId/agent', invokeAgentController);

export default router;
