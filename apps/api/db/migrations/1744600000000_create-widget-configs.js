/**
 * Migración 006 — Tabla widget_configs
 *
 * Configuración del widget de chat web embebible "Kairos".
 * Cada tenant tiene una config con una site_key pública que el cliente
 * pega en su sitio (<script ... data-axiia-key="...">). El widget resuelve
 * el tenant por esa site_key, sin exponer el JWT del panel.
 *
 * Campos de conocimiento (source_url / knowledge) quedan preparados para la
 * Fase 2 (autoconfiguración por scraping del sitio del cliente).
 */

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const up = (pgm) => {
  pgm.createTable('widget_configs', {
    id: {
      type: 'uuid',
      primaryKey: true,
      default: pgm.func('gen_random_uuid()'),
    },
    tenant_id: {
      type: 'uuid',
      notNull: true,
      references: '"tenants"(id)',
      onDelete: 'CASCADE',
    },
    // Clave pública que identifica al tenant desde el sitio del cliente.
    site_key: {
      type: 'text',
      notNull: true,
    },
    // Nombre del asistente que se muestra en el widget.
    bot_name: {
      type: 'text',
      notNull: true,
      default: 'Kairos',
    },
    // Saludo inicial. Si es null, el widget usa uno por defecto.
    greeting: {
      type: 'text',
      notNull: false,
    },
    // Color de acento del widget (header / botones).
    accent: {
      type: 'text',
      notNull: true,
      default: '#0B1D3F',
    },
    // Si está deshabilitado, el widget no se muestra.
    enabled: {
      type: 'boolean',
      notNull: true,
      default: true,
    },
    // Orígenes permitidos. Vacío = se permite cualquier sitio (MVP).
    allowed_origins: {
      type: 'jsonb',
      notNull: true,
      default: pgm.func("'[]'::jsonb"),
    },
    // ── Fase 2: autoconfiguración por scraping ──────────────────────────────
    // URL del sitio del cliente que se scrapea para generar el conocimiento.
    source_url: {
      type: 'text',
      notNull: false,
    },
    // Base de conocimiento generada a partir del sitio (texto inyectado al prompt).
    knowledge: {
      type: 'text',
      notNull: false,
    },
    created_at: {
      type: 'timestamptz',
      notNull: true,
      default: pgm.func('now()'),
    },
    updated_at: {
      type: 'timestamptz',
      notNull: true,
      default: pgm.func('now()'),
    },
  });

  // Un tenant = una config de widget.
  pgm.createIndex('widget_configs', 'tenant_id', { unique: true });

  // Lookup público por site_key (request entrante del widget).
  pgm.createIndex('widget_configs', 'site_key', { unique: true });
};

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const down = (pgm) => {
  pgm.dropTable('widget_configs');
};
