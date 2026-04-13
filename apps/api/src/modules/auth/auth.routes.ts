import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { registerController } from './auth.controller';
import { loginController } from './auth.login.controller';
import { refreshController, logoutController } from './auth.refresh.controller';
import { authMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();

// Rate limiter para endpoints sensibles de autenticación.
// Previene ataques de fuerza bruta (probar miles de passwords).
// Configuración: máximo 10 intentos por IP en una ventana de 15 minutos.
// En producción se puede bajar a 5 y agregar lockout progresivo.
const authLimiter = rateLimit({
  windowMs:         15 * 60 * 1000, // 15 minutos en milisegundos
  max:              10,              // máximo 10 requests por IP en esa ventana
  standardHeaders:  true,           // incluye headers Retry-After y RateLimit-* en la respuesta
  legacyHeaders:    false,
  message:          { error: 'Demasiados intentos. Intentá nuevamente en 15 minutos.' },
});

// POST /api/auth/register — authLimiter previene creación masiva de cuentas
router.post('/register', authLimiter, registerController);

// POST /api/auth/login — authLimiter previene fuerza bruta
router.post('/login', authLimiter, loginController);

// POST /api/auth/refresh — authLimiter previene rotación masiva de tokens
router.post('/refresh', authLimiter, refreshController);

// POST /api/auth/logout — revoca todos los refresh tokens del usuario
// Requiere estar autenticado (el access token aún no venció)
router.post('/logout', authMiddleware, logoutController);

export default router;
