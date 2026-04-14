/**
 * Migración 005 — Tabla whatsapp_connections
 *
 * Almacena la configuración de WhatsApp Business por tenant.
 * Preparada para Meta WhatsApp Cloud API + Embedded Signup.
 * Un tenant puede tener un número de WhatsApp activo a la vez.
 */

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const up = (pgm) => {
  pgm.createTable('whatsapp_connections', {
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
    // WABA = WhatsApp Business Account ID (nivel de cuenta, desde Meta)
    waba_id: {
      type: 'text',
      notNull: false,
    },
    // Phone Number ID único por número en Meta
    phone_number_id: {
      type: 'text',
      notNull: false,
    },
    // Número en formato internacional (ej: +5491112345678)
    phone_number: {
      type: 'text',
      notNull: false,
    },
    // Token de acceso del sistema (permanente) o de usuario (temporal)
    access_token: {
      type: 'text',
      notNull: false,
    },
    status: {
      type: 'text',
      notNull: true,
      default: 'pending',
      check: "status IN ('pending', 'active', 'inactive', 'error')",
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

  // Un tenant = un número activo a la vez
  pgm.createIndex('whatsapp_connections', 'tenant_id', { unique: true });

  // Lookup por phone_number_id (webhook entrante)
  pgm.createIndex('whatsapp_connections', 'phone_number_id');
};

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const down = (pgm) => {
  pgm.dropTable('whatsapp_connections');
};
