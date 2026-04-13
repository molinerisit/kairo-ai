import type { Request, Response } from 'express';
import { rotateRefreshToken, revokeAllTokens } from './auth.refresh.service';

// POST /api/auth/refresh
// Recibe un refresh_token y devuelve un nuevo par (access_token + refresh_token).
// El refresh token viejo queda revocado (rotación).
export async function refreshController(req: Request, res: Response): Promise<void> {
  const { refresh_token } = req.body as { refresh_token?: string };

  if (!refresh_token || typeof refresh_token !== 'string') {
    res.status(400).json({ error: 'refresh_token requerido' });
    return;
  }

  try {
    const tokens = await rotateRefreshToken(refresh_token, {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip,
    });

    if (!tokens) {
      // Token inválido, vencido o ya usado
      res.status(401).json({ error: 'Token inválido o vencido' });
      return;
    }

    res.json({
      access_token:  tokens.accessToken,
      refresh_token: tokens.refreshToken,
      token_type: 'Bearer',
    });
  } catch (err) {
    console.error('[Auth/Refresh]', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
}

// POST /api/auth/logout
// Revoca todos los refresh tokens del usuario. Requiere estar autenticado.
export async function logoutController(req: Request, res: Response): Promise<void> {
  try {
    // req.user viene del authMiddleware
    await revokeAllTokens(req.user!.user_id);
    res.status(204).send();
  } catch (err) {
    console.error('[Auth/Logout]', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
}
