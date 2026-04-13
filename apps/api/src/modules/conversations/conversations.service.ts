import { query } from '../../shared/db/pool';
import type { Conversation, Message } from './conversations.types';
import type {
  CreateConversationInput,
  UpdateConversationInput,
  CreateMessageInput,
} from './conversations.schema';

// ── CONVERSACIONES ────────────────────────────────────────────────────────────

// Listar conversaciones del tenant, ordenadas por actividad reciente.
// last_message_at DESC: las que tuvieron actividad reciente aparecen primero.
export async function listConversations(
  tenantId: string,
  limit = 50,
  offset = 0
): Promise<Conversation[]> {
  const result = await query<Conversation>(
    `SELECT id, tenant_id, channel, contact_phone, contact_name,
            status, assigned_to, last_message_at, metadata, created_at, updated_at
     FROM conversations
     WHERE tenant_id = $1
     ORDER BY COALESCE(last_message_at, created_at) DESC
     LIMIT $2 OFFSET $3`,
    [tenantId, limit, offset]
  );
  return result.rows;
}

export async function getConversation(
  tenantId: string,
  conversationId: string
): Promise<Conversation | null> {
  const result = await query<Conversation>(
    `SELECT id, tenant_id, channel, contact_phone, contact_name,
            status, assigned_to, last_message_at, metadata, created_at, updated_at
     FROM conversations
     WHERE id = $1 AND tenant_id = $2`,
    [conversationId, tenantId]
  );
  return result.rows[0] ?? null;
}

export async function createConversation(
  tenantId: string,
  input: CreateConversationInput
): Promise<Conversation> {
  const result = await query<Conversation>(
    `INSERT INTO conversations (tenant_id, channel, contact_phone, contact_name, metadata)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, tenant_id, channel, contact_phone, contact_name,
               status, assigned_to, last_message_at, metadata, created_at, updated_at`,
    [
      tenantId,
      input.channel,
      input.contact_phone ?? null,
      input.contact_name  ?? null,
      JSON.stringify(input.metadata),
    ]
  );
  return result.rows[0];
}

export async function updateConversation(
  tenantId: string,
  conversationId: string,
  input: UpdateConversationInput
): Promise<Conversation | null> {
  // Construimos el SET dinámicamente para solo actualizar los campos que vienen
  const fields: string[] = [];
  const values: unknown[] = [];
  let idx = 1;

  if (input.status !== undefined)      { fields.push(`status = $${idx++}`);      values.push(input.status); }
  if (input.assigned_to !== undefined) { fields.push(`assigned_to = $${idx++}`); values.push(input.assigned_to); }
  if (input.contact_name !== undefined){ fields.push(`contact_name = $${idx++}`);values.push(input.contact_name); }

  if (fields.length === 0) return getConversation(tenantId, conversationId);

  values.push(conversationId, tenantId);

  const result = await query<Conversation>(
    `UPDATE conversations
     SET ${fields.join(', ')}
     WHERE id = $${idx++} AND tenant_id = $${idx}
     RETURNING id, tenant_id, channel, contact_phone, contact_name,
               status, assigned_to, last_message_at, metadata, created_at, updated_at`,
    values
  );
  return result.rows[0] ?? null;
}

// ── MENSAJES ──────────────────────────────────────────────────────────────────

export async function listMessages(
  tenantId: string,
  conversationId: string,
  limit = 100,
  offset = 0
): Promise<Message[]> {
  const result = await query<Message>(
    `SELECT id, tenant_id, conversation_id, role, content, agent_type, external_id, created_at
     FROM messages
     WHERE conversation_id = $1 AND tenant_id = $2
     ORDER BY created_at ASC
     LIMIT $3 OFFSET $4`,
    [conversationId, tenantId, limit, offset]
  );
  return result.rows;
}

// createMessage: inserta el mensaje Y actualiza last_message_at en la conversación.
// Esto mantiene el orden de la lista de conversaciones actualizado.
export async function createMessage(
  tenantId: string,
  conversationId: string,
  input: CreateMessageInput
): Promise<Message> {
  // Verificar que la conversación existe y pertenece al tenant
  const conv = await getConversation(tenantId, conversationId);
  if (!conv) throw { statusCode: 404, message: 'Conversación no encontrada' };

  const result = await query<Message>(
    `INSERT INTO messages (tenant_id, conversation_id, role, content, agent_type, external_id)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING id, tenant_id, conversation_id, role, content, agent_type, external_id, created_at`,
    [
      tenantId,
      conversationId,
      input.role,
      input.content,
      input.agent_type   ?? null,
      input.external_id  ?? null,
    ]
  );

  // Actualizar last_message_at en la conversación para mantener el orden de la lista
  await query(
    `UPDATE conversations SET last_message_at = now() WHERE id = $1`,
    [conversationId]
  );

  return result.rows[0];
}
