import type { Request, Response } from 'express';
import { env } from '../../config/env';
import { query } from '../../shared/db/pool';
import { createConversation, createMessage } from '../conversations/conversations.service';
import { runSecretary } from '../agents/secretary.agent';
import { getOrCreateConfig, getConfigBySiteKey, toPublicConfig } from './widget.service';
import { ingestSite } from './widget.ingest';

// ── EMBED (panel, requiere auth) ──────────────────────────────────────────────
// GET /api/widget/embed
// Provisiona la config del widget del tenant y devuelve el snippet listo para
// pegar en el sitio del cliente.
export async function embedController(req: Request, res: Response): Promise<void> {
  try {
    const tenantId = req.user!.tenant_id;
    const cfg = await getOrCreateConfig(tenantId);

    const base = (env.BASE_URL ?? `${req.protocol}://${req.get('host')}`).replace(/\/$/, '');
    const snippet =
      `<script src="${base}/widget/kairos.js" data-axiia-key="${cfg.site_key}" defer></script>`;

    res.json({
      site_key: cfg.site_key,
      snippet,
      config: toPublicConfig(cfg),
    });
  } catch (err) {
    console.error('[Widget] embedController error:', err);
    res.status(500).json({ error: 'No se pudo generar el widget' });
  }
}

// ── CONFIG PÚBLICA (la lee el widget al iniciar) ──────────────────────────────
// GET /api/widget/config?key=ax_xxx
export async function publicConfigController(req: Request, res: Response): Promise<void> {
  const key = String(req.query.key ?? '');
  if (!key) {
    res.status(400).json({ error: 'Falta el parámetro key' });
    return;
  }

  const cfg = await getConfigBySiteKey(key);
  if (!cfg) {
    res.status(404).json({ error: 'Widget no encontrado' });
    return;
  }

  res.json(toPublicConfig(cfg));
}

// ── CHAT PÚBLICO (mensajes del visitante) ─────────────────────────────────────
// POST /api/widget/chat  { key, message, visitor_id, page }
export async function chatController(req: Request, res: Response): Promise<void> {
  try {
    const { key, message, visitor_id, page, anchors } = (req.body ?? {}) as {
      key?: string; message?: string; visitor_id?: string; page?: string;
      anchors?: Array<{ id?: string; label?: string }>;
    };

    // Normalizar y acotar las anclas que manda el widget (DOM de la página).
    const pageAnchors = Array.isArray(anchors)
      ? anchors
          .filter(a => a && typeof a.id === 'string' && typeof a.label === 'string')
          .slice(0, 25)
          .map(a => ({ id: String(a.id).slice(0, 80), label: String(a.label).slice(0, 100) }))
      : [];

    if (!key || typeof message !== 'string' || !message.trim()) {
      res.status(400).json({ error: 'key y message son requeridos' });
      return;
    }
    if (message.length > 2000) {
      res.status(400).json({ error: 'Mensaje demasiado largo' });
      return;
    }

    const cfg = await getConfigBySiteKey(key);
    if (!cfg || !cfg.enabled) {
      res.status(404).json({ error: 'Widget no disponible' });
      return;
    }

    const tenantId = cfg.tenant_id;
    const visitor  = (visitor_id && String(visitor_id).slice(0, 64)) || `anon-${Date.now()}`;

    // 1. Reusar la conversación web abierta de este visitante, o crear una nueva.
    const convResult = await query<{ id: string }>(
      `SELECT id FROM conversations
       WHERE tenant_id = $1 AND channel = 'web'
         AND metadata->>'visitor_id' = $2 AND status = 'open'
       ORDER BY created_at DESC LIMIT 1`,
      [tenantId, visitor]
    );

    let conversationId: string;
    if (convResult.rows.length > 0) {
      conversationId = convResult.rows[0].id;
    } else {
      const conv = await createConversation(tenantId, {
        channel:      'web',
        contact_name: 'Visitante web',
        metadata:     { visitor_id: visitor, page: page ?? null },
      });
      conversationId = conv.id;
    }

    // 2. Persistir el mensaje del visitante (para que aparezca en el inbox).
    await createMessage(tenantId, conversationId, { role: 'user', content: message.trim() });

    // 3. Generar la respuesta con el agente (reusa toda la lógica de IA).
    //    Inyectamos el conocimiento del sitio del cliente (autoconfig, Fase 2).
    const result = await runSecretary({
      tenantId, conversationId, userMessage: message.trim(),
      extraKnowledge: cfg.knowledge ?? undefined,
      pageAnchors,
    });

    // Si el agente eligió un ancla, devolvemos su id + label para el botón "Llevame ahí".
    const anchor = result.anchorId
      ? pageAnchors.find(a => a.id === result.anchorId) ?? null
      : null;

    res.json({ answer: result.response, bot_name: cfg.bot_name, anchor });
  } catch (err) {
    console.error('[Widget] chatController error:', err);
    res.status(500).json({ error: 'No se pudo procesar el mensaje' });
  }
}

// ── INGESTA / AUTOCONFIG (panel, requiere auth) ───────────────────────────────
// POST /api/widget/ingest  { url }
// Scrapea el sitio del cliente y autoconfigura el widget (knowledge, saludo,
// quick-replies). Asegura que exista la config antes de ingestar.
export async function ingestController(req: Request, res: Response): Promise<void> {
  try {
    const tenantId = req.user!.tenant_id;
    const url = String((req.body ?? {}).url ?? '').trim();
    if (!url) {
      res.status(400).json({ error: 'Falta la url del sitio' });
      return;
    }

    await getOrCreateConfig(tenantId);            // garantiza fila existente
    const result = await ingestSite(tenantId, url);
    res.json(result);
  } catch (err) {
    const e = err as { statusCode?: number; message?: string };
    console.error('[Widget] ingestController error:', e?.message ?? err);
    res.status(e?.statusCode ?? 500).json({ error: e?.message ?? 'No se pudo analizar el sitio' });
  }
}
