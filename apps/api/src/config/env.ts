import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

// Validamos las variables de entorno al iniciar el servidor.
// Si falta alguna variable crítica, el servidor no arranca y muestra
// exactamente qué falta. Esto evita errores silenciosos en producción.
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.string().default('3000'),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL es requerida'),
  REDIS_URL: z.string().optional(),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET debe tener al menos 32 caracteres'),
  JWT_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),
  // OPENAI_API_KEY: requerida para que los agentes funcionen
  OPENAI_API_KEY: z.string().optional(),
  // WHATSAPP_VERIFY_TOKEN: token secreto para verificar el webhook de WhatsApp
  WHATSAPP_VERIFY_TOKEN: z.string().optional(),
  // WHATSAPP_ACCESS_TOKEN: token de la WhatsApp Business API para enviar mensajes
  WHATSAPP_ACCESS_TOKEN: z.string().optional(),
  // WHATSAPP_PHONE_NUMBER_ID: ID del número de WhatsApp registrado en Meta
  WHATSAPP_PHONE_NUMBER_ID: z.string().optional(),
  // EVOLUTION_API_URL: URL del servidor Evolution API (ej: https://evolution.up.railway.app)
  EVOLUTION_API_URL: z.string().optional(),
  // EVOLUTION_API_KEY: API key del servidor Evolution API (AUTHENTICATION_API_KEY)
  EVOLUTION_API_KEY: z.string().optional(),
  // ALLOWED_ORIGIN: dominio del frontend autorizado para CORS
  // En dev: http://localhost:8080 | En prod: URL de Vercel
  ALLOWED_ORIGIN: z.string().optional(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('[Config] Variables de entorno inválidas:');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
