import type { Request, Response } from 'express';
import { z } from 'zod';
import { runSecretary } from './secretary.agent';
import { createMessage } from '../conversations/conversations.service';
import { getConversation } from '../conversations/conversations.service';

const invokeSchema = z.object({
  message: z.string().min(1, 'El mensaje no puede estar vacío'),
});

// POST /api/conversations/:conversationId/agent
// Recibe un mensaje del usuario, lo guarda, llama al agente secretario
// y devuelve la respuesta de la IA.
export async function invokeAgentController(req: Request, res: Response): Promise<void> {
  const parsed = invokeSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }

  const tenantId       = req.user!.tenant_id;
  const conversationId = String(req.params['conversationId']);
  const { message }    = parsed.data;

  try {
    // Verificar que la conversación existe y pertenece al tenant
    const conv = await getConversation(tenantId, conversationId);
    if (!conv) {
      res.status(404).json({ error: 'Conversación no encontrada' });
      return;
    }

    // Guardar el mensaje del usuario en la DB antes de llamar al agente
    await createMessage(tenantId, conversationId, {
      role:    'user',
      content: message,
    });

    // Llamar al agente secretario
    const result = await runSecretary({ tenantId, conversationId, userMessage: message });

    res.json({
      response:   result.response,
      tokensUsed: result.tokensUsed,
      latencyMs:  result.latencyMs,
    });
  } catch (err) {
    // Error específico de API key no configurada
    if (err instanceof Error && err.message.includes('OPENAI_API_KEY')) {
      res.status(503).json({ error: err.message });
      return;
    }
    console.error('[Agent]', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
}
