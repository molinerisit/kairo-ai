import type { Request, Response } from 'express';
import { query } from '../../shared/db/pool';

// GET /api/stats
// Devuelve un resumen de métricas del tenant para el dashboard.
// Una sola query compuesta para minimizar round-trips a la DB.
export async function statsController(req: Request, res: Response): Promise<void> {
  const tenantId = req.user!.tenant_id;
  const today    = new Date().toISOString().split('T')[0]; // "2026-04-13"

  try {
    // Todas las métricas en una sola query usando subconsultas.
    // Más eficiente que hacer 5 queries separadas.
    const result = await query<{
      total_conversations: string;
      open_conversations:  string;
      events_today:        string;
      total_rows:          string;
      messages_today:      string;
    }>(
      `SELECT
         (SELECT COUNT(*) FROM conversations WHERE tenant_id = $1)                                    AS total_conversations,
         (SELECT COUNT(*) FROM conversations WHERE tenant_id = $1 AND status = 'open')                AS open_conversations,
         (SELECT COUNT(*) FROM calendar_events
          WHERE tenant_id = $1 AND starts_at::date = $2::date)                                        AS events_today,
         (SELECT COUNT(*) FROM dynamic_rows WHERE tenant_id = $1)                                     AS total_rows,
         (SELECT COUNT(*) FROM messages m
          JOIN conversations c ON c.id = m.conversation_id
          WHERE c.tenant_id = $1 AND m.created_at::date = $2::date)                                   AS messages_today`,
      [tenantId, today]
    );

    const row = result.rows[0];
    res.json({
      totalConversations: parseInt(row.total_conversations),
      openConversations:  parseInt(row.open_conversations),
      eventsToday:        parseInt(row.events_today),
      totalRows:          parseInt(row.total_rows),
      messagesToday:      parseInt(row.messages_today),
    });
  } catch (err) {
    console.error('[Stats]', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
}
