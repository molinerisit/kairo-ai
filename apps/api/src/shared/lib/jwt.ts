import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import type { JwtPayload } from '../../modules/auth/auth.types';

// Centralizamos la lógica de JWT en un solo lugar.
// Si mañana cambiamos el algoritmo o agregamos claims,
// lo cambiamos acá y afecta a todo el sistema.

export function signToken(payload: Omit<JwtPayload, 'iat' | 'exp'>): string {
  return jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: env.JWT_EXPIRES_IN as jwt.SignOptions['expiresIn'],
  });
}

export function verifyToken(token: string): JwtPayload {
  // Si el token es inválido o venció, jwt.verify lanza un error.
  // Lo dejamos propagar — el middleware de auth lo captura.
  return jwt.verify(token, env.JWT_SECRET) as JwtPayload;
}
