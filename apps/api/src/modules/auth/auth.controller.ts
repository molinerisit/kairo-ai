import type { Request, Response } from 'express';
import { registerSchema } from './auth.schema';
import * as authService from './auth.service';

// El controller tiene UNA sola responsabilidad:
// recibir el HTTP request, validar la entrada,
// llamar al service y devolver la HTTP response.
// La lógica de negocio NO va acá — va en el service.

export async function registerController(req: Request, res: Response): Promise<void> {
  // safeParse devuelve { success: true, data } o { success: false, error }
  // A diferencia de parse(), NO lanza una excepción si falla
  const parsed = registerSchema.safeParse(req.body);

  if (!parsed.success) {
    res.status(400).json({
      error: 'Datos inválidos',
      // flatten() convierte los errores de Zod en un objeto legible:
      // { email: ['Email inválido'], password: ['Mínimo 8 caracteres'] }
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  try {
    const result = await authService.register(parsed.data);
    res.status(201).json(result);
  } catch (err: unknown) {
    // Manejo de errores esperados (lanzados a propósito desde el service)
    if (isAppError(err) && err.statusCode === 409) {
      res.status(409).json({ error: err.message });
      return;
    }

    // Error inesperado: logueamos el detalle interno pero no lo
    // exponemos al cliente (podría filtrar información sensible)
    console.error('[Auth] Error en registro:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
}

// Type guard: verifica en runtime si un valor es un AppError
function isAppError(err: unknown): err is { statusCode: number; message: string } {
  return (
    typeof err === 'object' &&
    err !== null &&
    'statusCode' in err &&
    'message' in err
  );
}
