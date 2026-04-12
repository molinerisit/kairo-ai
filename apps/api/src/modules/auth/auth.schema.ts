import { z } from 'zod';

// Zod valida la forma y el tipo de los datos que llegan en el body
// del request ANTES de que lleguen al service.
// Si los datos son inválidos, devolvemos 400 sin tocar la base de datos.

export const registerSchema = z.object({
  email: z.string().email('Email inválido'),
  password: z.string().min(8, 'La contraseña debe tener al menos 8 caracteres'),
  business_name: z.string().min(2, 'El nombre del negocio es requerido'),
});

export const loginSchema = z.object({
  email: z.string().email('Email inválido'),
  password: z.string().min(1, 'La contraseña es requerida'),
});

// z.infer extrae el tipo TypeScript del schema de Zod.
// Así no tenemos que definir el tipo a mano — lo derivamos del schema.
export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
