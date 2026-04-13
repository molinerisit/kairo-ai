import type { Request, Response } from 'express';
import { getTenantIdBySlug, onConnected, onDisconnected } from '../evolution/evolution.service';
import { sendText } from '../evolution/evolution.client';
import { runSecretary } from '../agents/secretary.agent';
import { createConversation } from '../conversations/conversations.service';
import { query } from '../../shared/db/pool';

// evolution.controller.ts — webhook receiver para Evolution API.
//
// Evolution API envía todos los eventos de todas las instancias a esta URL.
// Cada evento incluye el campo "instance" con el slug del tenant → ruteo O(1).
//
// Eventos que procesamos:
//   messages.upsert     → mensaje entrante del cliente
//   connection.update   → cambio de estado (connected / disconnected)
//   qrcode.updated      → QR regenerado (ignorado, el frontend hace polling)

export async function evolutionWebhookController(req: Request, res: Response): Promise<void> {
  // Responder 200 inmediatamente — Evolution reintenta si no recibe respuesta rápida
  res.status(200).json({ ok: true });

  const { event, instance, data } = req.body as {
    event:    string;
    instance: string;  // slug del tenant
    data:     Record<string, unknown>;
  };

  if (!event || !instance) return;

  handleEventAsync(event, instance, data).catch(err => {
    console.error(`[Evolution Webhook] Error en evento "${event}" instancia "${instance}":`, err);
  });
}

// ── Dispatcher ────────────────────────────────────────────────────────────────

async function handleEventAsync(
  event:    string,
  instance: string,
  data:     Record<string, unknown>,
): Promise<void> {
  switch (event) {
    case 'messages.upsert':
      await handleIncomingMessage(instance, data);
      break;
    case 'connection.update':
      await handleConnectionUpdate(instance, data);
      break;
    // qrcode.updated: el frontend hace polling de /api/evolution/status → ignorar
  }
}

// ── Mensaje entrante ──────────────────────────────────────────────────────────

async function handleIncomingMessage(
  slug: string,
  data: Record<string, unknown>,
): Promise<void> {
  // Ignorar mensajes enviados por nosotros
  const key = data['key'] as Record<string, unknown> | undefined;
  if (key?.['fromMe']) return;

  // Extraer texto del mensaje
  const message = data['message'] as Record<string, unknown> | undefined;
  const text = (message?.['conversation'] as string)
    ?? (message?.['extendedTextMessage'] as Record<string, unknown>)?.['text'] as string
    ?? null;

  if (!text) return; // Solo procesamos mensajes de texto por ahora

  const remoteJid   = key?.['remoteJid'] as string ?? '';          // "5491112345678@s.whatsapp.net"
  const phone       = remoteJid.replace('@s.whatsapp.net', '');    // "5491112345678"
  const contactName = (data['pushName'] as string | undefined) ?? 'Sin nombre';
  const msgId       = key?.['id'] as string ?? '';

  // Identificar tenant por slug de instancia
  const tenantId = await getTenantIdBySlug(slug);
  if (!tenantId) {
    console.warn(`[Evolution] No tenant found for instance "${slug}"`);
    return;
  }

  // Buscar conversación abierta del contacto o crear una nueva
  const existingConv = await query<{ id: string }>(
    `SELECT id FROM conversations
     WHERE tenant_id = $1 AND contact_phone = $2 AND channel = 'whatsapp' AND status = 'open'
     ORDER BY created_at DESC LIMIT 1`,
    [tenantId, phone]
  );

  let conversationId: string;
  if (existingConv.rows.length > 0) {
    conversationId = existingConv.rows[0].id;
  } else {
    const conv = await createConversation(tenantId, {
      channel:       'whatsapp',
      contact_phone: phone,
      contact_name:  contactName,
      metadata:      { external_id: msgId, instance: slug },
    });
    conversationId = conv.id;
  }

  // Llamar al agente secretario (guarda user + assistant en DB, llama a OpenAI)
  const result = await runSecretary({ tenantId, conversationId, userMessage: text });

  // Enviar respuesta por WhatsApp
  await sendText(slug, phone, result.response);
}

// ── Cambio de estado de conexión ─────────────────────────────────────────────

async function handleConnectionUpdate(
  slug: string,
  data: Record<string, unknown>,
): Promise<void> {
  const state = data['state'] as string | undefined;

  if (state === 'open') {
    // Extraer el número de teléfono del campo wuid si está disponible
    const wuid  = data['wuid'] as string | undefined;        // "5491112345678@s.whatsapp.net"
    const phone = wuid?.replace('@s.whatsapp.net', '') ?? '';
    await onConnected(slug, phone);
    console.log(`[Evolution] Instancia "${slug}" conectada — número: ${phone}`);
  } else if (state === 'close') {
    await onDisconnected(slug);
    console.log(`[Evolution] Instancia "${slug}" desconectada`);
  }
}
