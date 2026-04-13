import { z } from 'zod';

export const createEventSchema = z.object({
  title:        z.string().min(1, 'El título es requerido'),
  description:  z.string().optional(),
  starts_at:    z.string().min(1, 'starts_at es requerido'),
  ends_at:      z.string().min(1, 'ends_at es requerido'),
  contact_data: z.record(z.string(), z.unknown()).default({}),
  metadata:     z.record(z.string(), z.unknown()).default({}),
});

export const updateEventSchema = z.object({
  title:        z.string().min(1).optional(),
  description:  z.string().optional().nullable(),
  starts_at:    z.string().optional(),
  ends_at:      z.string().optional(),
  status:       z.enum(['scheduled', 'confirmed', 'cancelled', 'completed']).optional(),
  contact_data: z.record(z.string(), z.unknown()).optional(),
  metadata:     z.record(z.string(), z.unknown()).optional(),
});

// Filtros para listar eventos por rango de fechas
export const listEventsSchema = z.object({
  from:   z.string().optional(),
  to:     z.string().optional(),
  status: z.enum(['scheduled', 'confirmed', 'cancelled', 'completed']).optional(),
});

export type CreateEventInput  = z.infer<typeof createEventSchema>;
export type UpdateEventInput  = z.infer<typeof updateEventSchema>;
export type ListEventsFilters = z.infer<typeof listEventsSchema>;
