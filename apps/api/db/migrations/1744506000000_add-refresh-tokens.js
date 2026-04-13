/**
 * Migración 002 — Tabla de refresh tokens
 *
 * Por qué una tabla y no guardar el refresh token en el JWT:
 * - El JWT es stateless (sin estado): no se puede invalidar antes de que venza.
 * - Un refresh token en DB se puede invalidar al hacer logout o detectar uso sospechoso.
 * - Si alguien roba el refresh token, se puede revocar. Con JWT puro, no se puede.
 */

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const up = (pgm) => {
  pgm.createTable('refresh_tokens', {
    id:         { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    user_id:    { type: 'uuid', notNull: true, references: 'users', onDelete: 'CASCADE' },
    tenant_id:  { type: 'uuid', notNull: true, references: 'tenants', onDelete: 'CASCADE' },
    // token: valor opaco (UUID aleatorio), NO contiene datos — solo es una llave
    token:      { type: 'text', notNull: true, unique: true },
    // expires_at: cuándo vence este refresh token (7 días)
    expires_at: { type: 'timestamptz', notNull: true },
    // revoked_at: si no es null, el token fue invalidado (logout o seguridad)
    revoked_at: { type: 'timestamptz' },
    // user_agent / ip: para detectar uso desde dispositivos distintos
    user_agent: { type: 'text' },
    ip_address: { type: 'text' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  pgm.createIndex('refresh_tokens', 'user_id', { name: 'idx_refresh_tokens_user_id' });
  pgm.createIndex('refresh_tokens', 'token',   { name: 'idx_refresh_tokens_token' });
};

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const down = (pgm) => {
  pgm.dropTable('refresh_tokens');
};
