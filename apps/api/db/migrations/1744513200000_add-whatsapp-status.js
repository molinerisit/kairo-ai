/**
 * Migración 004 — Agrega whatsapp_status a business_profiles
 *
 * Registra el estado de la conexión de WhatsApp via Evolution API.
 * El nombre de instancia en Evolution API = slug del tenant (ya es único).
 */

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const up = (pgm) => {
  pgm.addColumn('business_profiles', {
    whatsapp_status: {
      type: 'text',
      notNull: true,
      default: 'disconnected',
      check: "whatsapp_status IN ('disconnected', 'connecting', 'connected')",
    },
  });
};

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const down = (pgm) => {
  pgm.dropColumn('business_profiles', 'whatsapp_status');
};
