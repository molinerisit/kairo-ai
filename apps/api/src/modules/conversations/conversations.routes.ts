import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import {
  listConversationsController,
  getConversationController,
  createConversationController,
  updateConversationController,
  listMessagesController,
  createMessageController,
} from './conversations.controller';

const router = Router();

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// ── Conversaciones ────────────────────────────────────────────────
// GET  /api/conversations        → listar conversaciones del tenant
// POST /api/conversations        → crear conversación nueva
// GET  /api/conversations/:id    → obtener conversación por id
// PATCH /api/conversations/:id   → actualizar status / assigned_to

router.get ('/',                    listConversationsController);
router.post('/',                    createConversationController);
router.get ('/:conversationId',     getConversationController);
router.patch('/:conversationId',    updateConversationController);

// ── Mensajes ──────────────────────────────────────────────────────
// GET  /api/conversations/:id/messages  → historial de mensajes
// POST /api/conversations/:id/messages  → agregar mensaje

router.get ('/:conversationId/messages', listMessagesController);
router.post('/:conversationId/messages', createMessageController);

export default router;
