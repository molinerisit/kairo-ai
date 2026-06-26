/**
 * Migración 007 — widget_configs.quick_replies
 *
 * Quick-replies (las "opciones" que se muestran como chips en el widget),
 * autogeneradas a partir del contenido del sitio del cliente (Fase 2).
 */

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const up = (pgm) => {
  pgm.addColumn('widget_configs', {
    quick_replies: {
      type: 'jsonb',
      notNull: true,
      default: pgm.func("'[]'::jsonb"),
    },
  });
};

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const down = (pgm) => {
  pgm.dropColumn('widget_configs', 'quick_replies');
};
