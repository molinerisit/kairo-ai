import type { Request, Response } from 'express';
import { loginSchema } from './auth.schema';
import { login } from './auth.login.service';

export async function loginController(req: Request, res: Response): Promise<void> {
  const parsed = loginSchema.safeParse(req.body);

  if (!parsed.success) {
    res.status(400).json({
      error: 'Datos inválidos',
      details: parsed.error.flatten().fieldErrors,
    });
    return;
  }

  try {
    const result = await login(parsed.data);
    res.status(200).json(result);
  } catch (err: unknown) {
    if (isAppError(err) && (err.statusCode === 401)) {
      res.status(401).json({ error: err.message });
      return;
    }
    console.error('[Auth] Error en login:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
}

function isAppError(err: unknown): err is { statusCode: number; message: string } {
  return typeof err === 'object' && err !== null && 'statusCode' in err && 'message' in err;
}
