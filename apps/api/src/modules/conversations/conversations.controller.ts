import type { Request, Response } from 'express';
import {
  createConversationSchema,
  updateConversationSchema,
  createMessageSchema,
} from './conversations.schema';
import * as service from './conversations.service';

const tenantId = (req: Request) => req.user!.tenant_id;
const param    = (req: Request, name: string) => String(req.params[name]);

function handleError(res: Response, err: unknown): void {
  if (isAppError(err)) { res.status(err.statusCode).json({ error: err.message }); return; }
  console.error('[Conversations]', err);
  res.status(500).json({ error: 'Error interno del servidor' });
}

function isAppError(err: unknown): err is { statusCode: number; message: string } {
  return typeof err === 'object' && err !== null && 'statusCode' in err && 'message' in err;
}

// ── CONVERSACIONES ────────────────────────────────────────────────────────────

export async function listConversationsController(req: Request, res: Response): Promise<void> {
  try {
    const limit  = Math.min(parseInt(req.query.limit  as string) || 50, 200);
    const offset = parseInt(req.query.offset as string) || 0;
    const convs  = await service.listConversations(tenantId(req), limit, offset);
    res.json(convs);
  } catch (err) { handleError(res, err); }
}

export async function getConversationController(req: Request, res: Response): Promise<void> {
  try {
    const conv = await service.getConversation(tenantId(req), param(req, 'conversationId'));
    if (!conv) { res.status(404).json({ error: 'Conversación no encontrada' }); return; }
    res.json(conv);
  } catch (err) { handleError(res, err); }
}

export async function createConversationController(req: Request, res: Response): Promise<void> {
  const parsed = createConversationSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }
  try {
    const conv = await service.createConversation(tenantId(req), parsed.data);
    res.status(201).json(conv);
  } catch (err) { handleError(res, err); }
}

export async function updateConversationController(req: Request, res: Response): Promise<void> {
  const parsed = updateConversationSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }
  try {
    const conv = await service.updateConversation(tenantId(req), param(req, 'conversationId'), parsed.data);
    if (!conv) { res.status(404).json({ error: 'Conversación no encontrada' }); return; }
    res.json(conv);
  } catch (err) { handleError(res, err); }
}

// ── MENSAJES ──────────────────────────────────────────────────────────────────

export async function listMessagesController(req: Request, res: Response): Promise<void> {
  try {
    const limit  = Math.min(parseInt(req.query.limit  as string) || 100, 500);
    const offset = parseInt(req.query.offset as string) || 0;
    const msgs   = await service.listMessages(tenantId(req), param(req, 'conversationId'), limit, offset);
    res.json(msgs);
  } catch (err) { handleError(res, err); }
}

export async function createMessageController(req: Request, res: Response): Promise<void> {
  const parsed = createMessageSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }
  try {
    const msg = await service.createMessage(tenantId(req), param(req, 'conversationId'), parsed.data);
    res.status(201).json(msg);
  } catch (err) { handleError(res, err); }
}
