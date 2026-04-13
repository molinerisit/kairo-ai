import type { Request, Response } from 'express';
import { z } from 'zod';
import { query } from '../../shared/db/pool';
import { createConversation } from '../conversations/conversations.service';
import { runSecretary } from '../agents/secretary.agent';
import { randomUUID } from 'crypto';

const simulateSchema = z.object({
  message:       z.string().min(1, 'El mensaje no puede estar vacío'),
  contact_name:  z.string().optional().default('Cliente de prueba'),
  contact_phone: z.string().optional(),
});

// POST /api/webhook/simulate
// Simula un mensaje entrante de WhatsApp para poder probar el agente
// sin necesitar un número de WhatsApp Business real.
//
// Requiere JWT → usa el tenant_id del usuario autenticado.
// Crea (o reutiliza) una conversación de simulación, llama al agente
// y devuelve el conversationId + la respuesta generada.
export async function simulateController(req: Request, res: Response): Promise<void> {
  const parsed = simulateSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }

  const tenantId    = req.user!.tenant_id;
  const { message, contact_name, contact_phone } = parsed.data;

  // Número de teléfono del contacto simulado.
  // Si no se provee, usamos uno fijo para reutilizar siempre la misma conversación.
  const phone = contact_phone ?? '+5400000000000';

  try {
    // Buscar conversación abierta existente para este contacto simulado
    const existing = await query<{ id: string }>(
      `SELECT id FROM conversations
       WHERE tenant_id = $1
         AND contact_phone = $2
         AND channel = 'whatsapp'
         AND status = 'open'
       ORDER BY created_at DESC
       LIMIT 1`,
      [tenantId, phone]
    );

    let conversationId: string;

    if (existing.rows.length > 0) {
      conversationId = existing.rows[0].id;
    } else {
      const conv = await createConversation(tenantId, {
        channel:       'whatsapp',
        contact_phone: phone,
        contact_name,
        metadata:      { simulated: true, sessionId: randomUUID() },
      });
      conversationId = conv.id;
    }

    // Llamar al agente (guarda mensaje user + genera respuesta assistant)
    const result = await runSecretary({ tenantId, conversationId, userMessage: message });

    res.json({
      conversationId,
      response:   result.response,
      tokensUsed: result.tokensUsed,
      latencyMs:  result.latencyMs,
    });

  } catch (err) {
    console.error('[Simulate]', err);
    res.status(500).json({ error: 'Error al simular el mensaje' });
  }
}
