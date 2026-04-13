import { z } from 'zod';

export const createConversationSchema = z.object({
  channel:       z.enum(['whatsapp', 'web', 'api']).default('whatsapp'),
  contact_phone: z.string().optional(),
  contact_name:  z.string().optional(),
  metadata:      z.record(z.string(), z.unknown()).default({}),
});

export const updateConversationSchema = z.object({
  status:      z.enum(['open', 'resolved', 'archived']).optional(),
  assigned_to: z.string().uuid().optional().nullable(),
  contact_name: z.string().optional(),
});

export const createMessageSchema = z.object({
  role:       z.enum(['user', 'assistant', 'system']),
  content:    z.string().min(1, 'El contenido no puede estar vacío'),
  agent_type: z.string().optional(),
  external_id: z.string().optional(),
});

export type CreateConversationInput = z.infer<typeof createConversationSchema>;
export type UpdateConversationInput = z.infer<typeof updateConversationSchema>;
export type CreateMessageInput      = z.infer<typeof createMessageSchema>;
