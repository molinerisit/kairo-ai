import type { Request, Response } from 'express';
import { createHmac } from 'crypto';
import { env } from '../../config/env';
import {
  processIncomingMessage,
  type WhatsAppWebhookBody,
} from './whatsapp.service';

// GET /api/webhook/whatsapp
// Meta llama a este endpoint al configurar el webhook para verificarlo.
// Necesita responder con el hub.challenge para confirmar que es nuestro servidor.
export function verifyWebhook(req: Request, res: Response): void {
  const mode      = req.query['hub.mode']       as string;
  const token     = req.query['hub.verify_token'] as string;
  const challenge = req.query['hub.challenge']  as string;

  if (mode === 'subscribe' && token === env.WHATSAPP_VERIFY_TOKEN) {
    console.log('[Webhook] WhatsApp verificado correctamente');
    res.status(200).send(challenge);
  } else {
    console.warn('[Webhook] Token de verificación inválido');
    res.status(403).json({ error: 'Token inválido' });
  }
}

// POST /api/webhook/whatsapp
// Meta envía los mensajes entrantes aquí.
// IMPORTANTE: Meta espera respuesta 200 en < 15 segundos.
// Por eso procesamos el mensaje de forma asíncrona (fire and forget).
export function receiveWebhook(req: Request, res: Response): void {
  // Verificar firma HMAC para confirmar que el request viene de Meta
  // (y no de alguien que encontró nuestra URL)
  if (!verifySignature(req)) {
    res.status(401).json({ error: 'Firma inválida' });
    return;
  }

  // Responder 200 inmediatamente para que Meta no reintente
  res.status(200).json({ status: 'ok' });

  // Procesar el mensaje de forma asíncrona (no bloquea la respuesta)
  const body = req.body as WhatsAppWebhookBody;
  handleWebhookAsync(body).catch(err => {
    console.error('[Webhook] Error procesando mensaje:', err);
  });
}

// ── PRIVADO ───────────────────────────────────────────────────────────────────

async function handleWebhookAsync(body: WhatsAppWebhookBody): Promise<void> {
  if (body.object !== 'whatsapp_business_account') return;

  for (const entry of body.entry) {
    for (const change of entry.changes) {
      if (change.field !== 'messages') continue;

      const value    = change.value;
      const messages = value.messages ?? [];

      for (const msg of messages) {
        // Solo procesamos mensajes de texto por ahora
        if (msg.type !== 'text' || !msg.text?.body) continue;

        const contactName = value.contacts?.[0]?.profile?.name ?? 'Sin nombre';
        const phoneId     = value.metadata.phone_number_id;

        await processIncomingMessage(
          phoneId,
          msg.from,
          contactName,
          msg.text.body,
          msg.id,
        );
      }
    }
  }
}

// verifySignature: verifica que el request viene realmente de Meta.
// Meta firma cada request con HMAC-SHA256 usando el App Secret.
// Si no tenemos el App Secret configurado, aceptamos en dev (warning).
function verifySignature(req: Request): boolean {
  const appSecret = env.WHATSAPP_ACCESS_TOKEN;

  // En dev sin app secret configurado, aceptamos (para testing local)
  if (!appSecret) {
    console.warn('[Webhook] App secret no configurado — saltando verificación de firma');
    return true;
  }

  const signature = req.headers['x-hub-signature-256'] as string;
  if (!signature) return false;

  const expected = 'sha256=' + createHmac('sha256', appSecret)
    .update(JSON.stringify(req.body))
    .digest('hex');

  return signature === expected;
}
