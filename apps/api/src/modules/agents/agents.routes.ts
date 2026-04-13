import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import { invokeAgentController } from './agents.controller';

const router = Router();
router.use(authMiddleware);

// POST /api/conversations/:conversationId/agent
// Montado en server.ts bajo /api/conversations, así que el path aquí es solo /:id/agent
router.post('/:conversationId/agent', invokeAgentController);

export default router;
