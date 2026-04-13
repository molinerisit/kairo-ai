import { z } from 'zod';
import { randomUUID } from 'crypto';

// Schema de una columna individual
const columnSchema = z.object({
  // Si no viene id (columna nueva), generamos uno automáticamente
  id:       z.string().uuid().default(() => randomUUID()),
  name:     z.string().min(1, 'El nombre de la columna es requerido'),
  type:     z.enum(['text', 'number', 'date', 'status', 'phone', 'money', 'email', 'url']),
  required: z.boolean().default(false),
  // options solo es relevante cuando type === 'status'
  options:  z.array(z.string()).optional(),
});

// Crear una tabla nueva
export const createTableSchema = z.object({
  name:       z.string().min(1, 'El nombre de la tabla es requerido'),
  table_type: z.enum(['clients', 'appointments', 'leads', 'custom']).default('custom'),
  columns:    z.array(columnSchema).min(1, 'La tabla debe tener al menos una columna'),
});

// Agregar o reemplazar columnas en una tabla existente
export const updateColumnsSchema = z.object({
  columns: z.array(columnSchema).min(1),
});

// Crear o actualizar una fila
// data es un objeto libre: { "col_uuid": valor }
export const upsertRowSchema = z.object({
  data: z.record(z.string().uuid(), z.unknown()),
});

export type CreateTableInput   = z.infer<typeof createTableSchema>;
export type UpdateColumnsInput = z.infer<typeof updateColumnsSchema>;
export type UpsertRowInput     = z.infer<typeof upsertRowSchema>;
