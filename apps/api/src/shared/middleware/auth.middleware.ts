import type { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../lib/jwt';

// ── authMiddleware ────────────────────────────────────────────────
// Protege rutas que requieren estar autenticado.
//
// Flujo:
//   1. Lee el header Authorization
//   2. Verifica que tenga formato "Bearer <token>"
//   3. Verifica que el JWT sea válido y no esté vencido
//   4. Agrega req.user con los datos del token para que
//      el controller los use sin tener que re-verificar
//
// Uso en routes:
//   router.get('/mis-datos', authMiddleware, miController);

export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  // El cliente debe enviar: Authorization: Bearer eyJhbGci...
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Token no proporcionado' });
    return;
  }

  // Extraemos solo el token, sin la palabra "Bearer "
  const token = authHeader.slice(7);

  try {
    const payload = verifyToken(token);

    // Adjuntamos el contexto del usuario al request.
    // A partir de acá, cualquier middleware o controller
    // que venga después puede leer req.user sin verificar de nuevo.
    req.user = {
      user_id: payload.user_id,
      tenant_id: payload.tenant_id,
      role:      payload.role,
    };

    next(); // continuar al siguiente middleware o controller
  } catch {
    // verifyToken lanza error si el token es inválido o venció.
    // No exponemos el detalle del error (podría dar info útil a atacantes).
    res.status(401).json({ error: 'Token inválido o vencido' });
  }
}

// ── requireRole ───────────────────────────────────────────────────
// Middleware factory (función que devuelve un middleware).
// Restringe el acceso a uno o más roles específicos.
//
// Uso:
//   router.delete('/negocio', authMiddleware, requireRole('owner', 'superadmin'), deleteHandler);
//
// Si el usuario no tiene el rol requerido, devuelve 403 Forbidden.
// 401 = no autenticado. 403 = autenticado pero sin permiso.

export function requireRole(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user || !roles.includes(req.user.role)) {
      res.status(403).json({ error: 'Sin permisos para esta acción' });
      return;
    }
    next();
  };
}
