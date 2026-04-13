/**
 * Migración 003 — Módulo de conversaciones
 *
 * Modelo de datos para el historial de conversaciones de WhatsApp.
 * Una conversation = un hilo con un contacto (cliente).
 * Un message = un mensaje individual dentro del hilo.
 *
 * Diseño clave: los mensajes tienen role ('user' | 'assistant') — el mismo
 * formato que usan las APIs de IA (OpenAI, Claude) para el historial.
 * Esto nos permite pasar el historial directamente al agente sin transformar.
 */

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const up = (pgm) => {
  // ── CONVERSATIONS ─────────────────────────────────────────────
  // Cada conversación representa un hilo con un contacto específico.
  pgm.createTable('conversations', {
    id:           { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    tenant_id:    { type: 'uuid', notNull: true, references: 'tenants', onDelete: 'CASCADE' },
    // channel: por dónde llegó el contacto
    channel:      { type: 'text', notNull: true, default: 'whatsapp',
                    check: "channel IN ('whatsapp', 'web', 'api')" },
    // contact_phone: número de WhatsApp del contacto (puede ser null para canales no-phone)
    contact_phone: { type: 'text' },
    contact_name:  { type: 'text' },
    // status: estado del hilo — open=activo, resolved=resuelto, archived=archivado
    status:       { type: 'text', notNull: true, default: 'open',
                    check: "status IN ('open', 'resolved', 'archived')" },
    // assigned_to: usuario del panel que tiene asignada esta conversación (opcional)
    assigned_to:  { type: 'uuid', references: 'users', onDelete: 'SET NULL' },
    // last_message_at: desnormalización para ordenar la lista por actividad reciente
    last_message_at: { type: 'timestamptz' },
    // metadata: datos extra del canal (ej: whatsapp_message_id, thread_id)
    metadata:     { type: 'jsonb', notNull: true, default: '{}' },
    created_at:   { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
    updated_at:   { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  pgm.createIndex('conversations', 'tenant_id',       { name: 'idx_conversations_tenant_id' });
  pgm.createIndex('conversations', 'contact_phone',   { name: 'idx_conversations_phone' });
  pgm.createIndex('conversations', 'last_message_at', { name: 'idx_conversations_last_msg' });
  pgm.sql(`
    CREATE TRIGGER conversations_updated_at
      BEFORE UPDATE ON conversations
      FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  `);

  // ── MESSAGES ──────────────────────────────────────────────────
  // Cada mensaje dentro de una conversación.
  pgm.createTable('messages', {
    id:              { type: 'uuid', primaryKey: true, default: pgm.func('gen_random_uuid()') },
    tenant_id:       { type: 'uuid', notNull: true, references: 'tenants', onDelete: 'CASCADE' },
    conversation_id: { type: 'uuid', notNull: true, references: 'conversations', onDelete: 'CASCADE' },
    // role: 'user' = mensaje del cliente, 'assistant' = respuesta del agente IA
    // Este formato es compatible directo con la API de Claude y OpenAI
    role:            { type: 'text', notNull: true,
                       check: "role IN ('user', 'assistant', 'system')" },
    content:         { type: 'text', notNull: true },
    // agent_type: qué agente generó este mensaje (solo para role='assistant')
    agent_type:      { type: 'text' },
    // external_id: ID del mensaje en el canal externo (WhatsApp message ID)
    external_id:     { type: 'text' },
    created_at:      { type: 'timestamptz', notNull: true, default: pgm.func('now()') },
  });

  pgm.createIndex('messages', 'conversation_id', { name: 'idx_messages_conversation_id' });
  pgm.createIndex('messages', 'tenant_id',       { name: 'idx_messages_tenant_id' });
};

/** @param {import('node-pg-migrate').MigrationBuilder} pgm */
export const down = (pgm) => {
  pgm.dropTable('messages');
  pgm.dropTable('conversations');
};
