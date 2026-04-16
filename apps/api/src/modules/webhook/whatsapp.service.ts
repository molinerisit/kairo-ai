import { query } from '../../shared/db/pool';
import { createConversation } from '../conversations/conversations.service';
import { runSecretary } from '../agents/secretary.agent';
import { env } from '../../config/env';

// ── TIPOS DEL WEBHOOK DE WHATSAPP ─────────────────────────────────────────────
// La WhatsApp Business API envía eventos en este formato.
// Documentación: https://developers.facebook.com/docs/whatsapp/cloud-api/webhooks

export interface WhatsAppWebhookBody {
  object: string;
  entry:  WhatsAppEntry[];
}

interface WhatsAppEntry {
  id:      string;
  changes: WhatsAppChange[];
}

interface WhatsAppChange {
  value: WhatsAppValue;
  field: string;
}

interface WhatsAppValue {
  messaging_product: string;
  metadata:          { phone_number_id: string };
  contacts?:         Array<{ profile: { name: string }; wa_id: string }>;
  messages?:         WhatsAppMessage[];
}

interface WhatsAppMessage {
  from:      string;   // número del remitente en formato internacional
  id:        string;   // ID único del mensaje en WhatsApp
  timestamp: string;
  type:      string;   // 'text', 'image', 'audio', etc.
  text?:     { body: string };
}

// ── PROCESAR MENSAJE ENTRANTE ─────────────────────────────────────────────────

// processIncomingMessage: punto de entrada del flujo completo.
// 1. Identifica el tenant por el phone_number_id
// 2. Busca o crea la conversación del contacto
// 3. Llama al agente secretario
// 4. Envía la respuesta por WhatsApp
export async function processIncomingMessage(
  phoneNumberId: string,
  from:          string,   // número del cliente ej: "5491112345678"
  contactName:   string,
  messageText:   string,
  externalMsgId: string   // ID del mensaje en WhatsApp para deduplicación
): Promise<void> {
  // 1. Encontrar qué tenant tiene este número de WhatsApp
  //    Resolvemos por whatsapp_connections.phone_number_id (arquitectura multi-tenant)
  const tenantResult = await query<{ tenant_id: string }>(
    `SELECT tenant_id FROM whatsapp_connections
     WHERE phone_number_id = $1 AND status = 'active'`,
    [phoneNumberId]
  );

  if (tenantResult.rows.length === 0) {
    console.warn(`[Webhook] No se encontró tenant activo para phone_number_id: ${phoneNumberId}`);
    return;
  }

  const tenantId = tenantResult.rows[0].tenant_id;
  const phone    = `+${from}`;

  // 2. Buscar conversación existente de este contacto o crear una nueva
  const convResult = await query<{ id: string }>(
    `SELECT id FROM conversations
     WHERE tenant_id = $1 AND contact_phone = $2 AND status = 'open'
     ORDER BY created_at DESC LIMIT 1`,
    [tenantId, phone]
  );

  let conversationId: string;

  if (convResult.rows.length > 0) {
    conversationId = convResult.rows[0].id;
  } else {
    // Primera vez que este contacto escribe → crear conversación nueva
    const conv = await createConversation(tenantId, {
      channel:       'whatsapp',
      contact_phone: phone,
      contact_name:  contactName,
      metadata:      { phone_number_id: phoneNumberId },
    });
    conversationId = conv.id;
  }

  // 3. Llamar al agente secretario (guarda mensaje user + genera respuesta assistant)
  const result = await runSecretary({ tenantId, conversationId, userMessage: messageText });

  // 4. Enviar la respuesta por WhatsApp
  await sendWhatsAppMessage(from, result.response, phoneNumberId);
}

// ── ENVIAR MENSAJE POR WHATSAPP ───────────────────────────────────────────────

async function sendWhatsAppMessage(
  to:            string,
  message:       string,
  phoneNumberId: string
): Promise<void> {
  if (!env.WHATSAPP_ACCESS_TOKEN) {
    console.warn('[Webhook] WHATSAPP_ACCESS_TOKEN no configurado — mensaje no enviado');
    return;
  }

  const url = `https://graph.facebook.com/v18.0/${phoneNumberId}/messages`;

  const response = await fetch(url, {
    method:  'POST',
    headers: {
      'Content-Type':  'application/json',
      'Authorization': `Bearer ${env.WHATSAPP_ACCESS_TOKEN}`,
    },
    body: JSON.stringify({
      messaging_product: 'whatsapp',
      to,
      type: 'text',
      text: { body: message },
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error('[Webhook] Error al enviar mensaje WhatsApp:', error);
  }
}
