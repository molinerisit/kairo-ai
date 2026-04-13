/**
 * Migración 001 — Schema inicial de Kairo AI
 *
 * Esta migración crea todas las tablas del sistema desde cero.
 * Representa el estado al final del Sprint 1.
 *
 * node-pg-migrate usa funciones up() y down():
 *   up()   → se ejecuta al aplicar la migración (migrate:up)
 *   down() → se ejecuta al revertirla (migrate:down)
 *
 * Siempre escribir ambas para poder hacer rollback seguro.
 */

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const up = (pgm) => {
  // Extensión para UUIDs (Universally Unique Identifiers)
  pgm.createExtension('pgcrypto', { ifNotExists: true });

  // ── TENANTS ────────────────────────────────────────────────────
  pgm.createTable('tenants', {
    id:         { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    name:       { type: 'text', notNull: true },
    slug:       { type: 'text', notNull: true, unique: true },
    industry:   { type: 'text' },
    plan:       { type: 'text', notNull: true, default: 'starter',
                  check: "plan IN ('starter', 'growth', 'executive')" },
    status:     { type: 'text', notNull: true, default: 'trial',
                  check: "status IN ('trial', 'active', 'suspended')" },
    settings:   { type: 'jsonb', notNull: true, default: '{}' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  // ── USERS ──────────────────────────────────────────────────────
  pgm.createTable('users', {
    id:            { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    tenant_id:     { type: 'uuid', references: 'tenants', onDelete: 'CASCADE' },
    email:         { type: 'text', notNull: true, unique: true },
    password_hash: { type: 'text', notNull: true },
    role:          { type: 'text', notNull: true, default: 'operator',
                     check: "role IN ('superadmin', 'owner', 'operator')" },
    full_name:     { type: 'text' },
    is_active:     { type: 'boolean', notNull: true, default: true },
    created_at:    { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at:    { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex('users', 'tenant_id', { name: 'idx_users_tenant_id' });

  // ── BUSINESS PROFILES ─────────────────────────────────────────
  pgm.createTable('business_profiles', {
    id:          { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    tenant_id:   { type: 'uuid', notNull: true, unique: true, references: 'tenants', onDelete: 'CASCADE' },
    tone:        { type: 'text' },
    description: { type: 'text' },
    hours:       { type: 'jsonb', notNull: true, default: '{}' },
    services:    { type: 'jsonb', notNull: true, default: '[]' },
    faqs:        { type: 'jsonb', notNull: true, default: '[]' },
    whatsapp:    { type: 'text' },
    address:     { type: 'text' },
    updated_at:  { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  // ── TRIGGER FUNCTION update_updated_at ────────────────────────
  // Se crea una vez y se reutiliza en todos los triggers de la DB.
  pgm.sql(`
    CREATE OR REPLACE FUNCTION update_updated_at()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = now();
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
  `);

  // Aplicar trigger a tablas con updated_at
  for (const table of ['tenants', 'users', 'business_profiles']) {
    pgm.sql(`
      CREATE TRIGGER ${table}_updated_at
        BEFORE UPDATE ON ${table}
        FOR EACH ROW EXECUTE FUNCTION update_updated_at();
    `);
  }

  // ── DYNAMIC TABLES ────────────────────────────────────────────
  // Cada tenant puede crear tablas personalizadas (CRM, leads, inventario…).
  // Las definiciones de columnas se guardan como JSONB.
  pgm.createTable('dynamic_tables', {
    id:         { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    tenant_id:  { type: 'uuid', notNull: true, references: 'tenants', onDelete: 'CASCADE' },
    name:       { type: 'text', notNull: true },
    table_type: { type: 'text', notNull: true, default: 'custom' },
    columns:    { type: 'jsonb', notNull: true, default: '[]' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex('dynamic_tables', 'tenant_id', { name: 'idx_dynamic_tables_tenant_id' });
  pgm.sql(`
    CREATE TRIGGER dynamic_tables_updated_at
      BEFORE UPDATE ON dynamic_tables
      FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  `);

  // ── DYNAMIC ROWS ──────────────────────────────────────────────
  // Los valores de cada fila se guardan como JSONB:
  // { "col-uuid": valor, "col-uuid-2": valor2 }
  pgm.createTable('dynamic_rows', {
    id:         { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    tenant_id:  { type: 'uuid', notNull: true, references: 'tenants', onDelete: 'CASCADE' },
    table_id:   { type: 'uuid', notNull: true, references: 'dynamic_tables', onDelete: 'CASCADE' },
    data:       { type: 'jsonb', notNull: true, default: '{}' },
    created_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at: { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex('dynamic_rows', 'table_id',  { name: 'idx_dynamic_rows_table_id' });
  pgm.createIndex('dynamic_rows', 'tenant_id', { name: 'idx_dynamic_rows_tenant_id' });
  // Índice GIN (Generalized Inverted Index): permite búsquedas dentro del JSONB
  pgm.sql(`CREATE INDEX idx_dynamic_rows_data ON dynamic_rows USING GIN(data);`);
  pgm.sql(`
    CREATE TRIGGER dynamic_rows_updated_at
      BEFORE UPDATE ON dynamic_rows
      FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  `);

  // ── CALENDAR EVENTS ───────────────────────────────────────────
  pgm.createTable('calendar_events', {
    id:           { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    tenant_id:    { type: 'uuid', notNull: true, references: 'tenants', onDelete: 'CASCADE' },
    title:        { type: 'text', notNull: true },
    description:  { type: 'text' },
    starts_at:    { type: 'timestamptz', notNull: true },
    ends_at:      { type: 'timestamptz', notNull: true },
    status:       { type: 'text', notNull: true, default: 'scheduled',
                    check: "status IN ('scheduled', 'confirmed', 'cancelled', 'completed')" },
    contact_data: { type: 'jsonb', notNull: true, default: '{}' },
    metadata:     { type: 'jsonb', notNull: true, default: '{}' },
    created_at:   { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at:   { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
  pgm.createIndex('calendar_events', 'tenant_id', { name: 'idx_calendar_events_tenant_id' });
  pgm.createIndex('calendar_events', 'starts_at',  { name: 'idx_calendar_events_starts_at' });
  pgm.sql(`
    CREATE TRIGGER calendar_events_updated_at
      BEFORE UPDATE ON calendar_events
      FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  `);

  // ── AI LOGS ───────────────────────────────────────────────────
  pgm.createTable('ai_logs', {
    id:          { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    tenant_id:   { type: 'uuid', notNull: true, references: 'tenants', onDelete: 'CASCADE' },
    agent_type:  { type: 'text', notNull: true },
    channel:     { type: 'text', notNull: true, default: 'api' },
    input:       { type: 'text', notNull: true },
    output:      { type: 'text' },
    tokens_used: { type: 'integer' },
    latency_ms:  { type: 'integer' },
    error:       { type: 'text' },
    created_at:  { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });
};

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const down = (pgm) => {
  // Se eliminan en orden inverso por las foreign keys (referencias entre tablas)
  pgm.dropTable('ai_logs');
  pgm.dropTable('calendar_events');
  pgm.dropTable('dynamic_rows');
  pgm.dropTable('dynamic_tables');
  pgm.dropTable('business_profiles');
  pgm.dropTable('users');
  pgm.dropTable('tenants');
  pgm.sql('DROP FUNCTION IF EXISTS update_updated_at CASCADE;');
};
