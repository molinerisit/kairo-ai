import { randomBytes } from 'crypto';
import { query } from '../../shared/db/pool';

// ── TIPOS ─────────────────────────────────────────────────────────────────────

export interface WidgetConfig {
  id:              string;
  tenant_id:       string;
  site_key:        string;
  bot_name:        string;
  greeting:        string | null;
  accent:          string;
  enabled:         boolean;
  allowed_origins: string[];
  source_url:      string | null;
  knowledge:       string | null;
  quick_replies:   string[];
}

// Vista pública del config — lo que el widget necesita para renderizarse.
// Nunca expone tenant_id ni campos internos (knowledge, etc.).
export interface PublicWidgetConfig {
  bot_name:      string;
  greeting:      string;
  accent:        string;
  enabled:       boolean;
  quick_replies: string[];
}

const DEFAULT_GREETING = '¡Hola! Soy Kairos 👋 ¿En qué te puedo ayudar?';

// ── PROVISIONAR / OBTENER CONFIG POR TENANT ──────────────────────────────────

// Devuelve la config del widget del tenant, creándola con valores por defecto
// si todavía no existe. Idempotente: el panel la llama para mostrar el snippet.
export async function getOrCreateConfig(tenantId: string): Promise<WidgetConfig> {
  const existing = await query<WidgetConfig>(
    `SELECT id, tenant_id, site_key, bot_name, greeting, accent, enabled,
            allowed_origins, source_url, knowledge, quick_replies
     FROM widget_configs WHERE tenant_id = $1`,
    [tenantId]
  );
  if (existing.rows[0]) return existing.rows[0];

  const siteKey = generateSiteKey();
  const created = await query<WidgetConfig>(
    `INSERT INTO widget_configs (tenant_id, site_key)
     VALUES ($1, $2)
     RETURNING id, tenant_id, site_key, bot_name, greeting, accent, enabled,
               allowed_origins, source_url, knowledge, quick_replies`,
    [tenantId, siteKey]
  );
  return created.rows[0];
}

// ── RESOLVER TENANT POR SITE_KEY (request público del widget) ─────────────────

export async function getConfigBySiteKey(siteKey: string): Promise<WidgetConfig | null> {
  const result = await query<WidgetConfig>(
    `SELECT id, tenant_id, site_key, bot_name, greeting, accent, enabled,
            allowed_origins, source_url, knowledge, quick_replies
     FROM widget_configs WHERE site_key = $1`,
    [siteKey]
  );
  return result.rows[0] ?? null;
}

// ── HELPERS ──────────────────────────────────────────────────────────────────

export function toPublicConfig(cfg: WidgetConfig): PublicWidgetConfig {
  return {
    bot_name:      cfg.bot_name,
    greeting:      cfg.greeting ?? DEFAULT_GREETING,
    accent:        cfg.accent,
    enabled:       cfg.enabled,
    quick_replies: cfg.quick_replies ?? [],
  };
}

// site_key pública, no adivinable. Prefijo "ax_" para reconocerla de un vistazo.
function generateSiteKey(): string {
  return `ax_${randomBytes(18).toString('hex')}`;
}
