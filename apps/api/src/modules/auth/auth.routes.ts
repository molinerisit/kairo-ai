import { Router } from 'express';
import { registerController } from './auth.controller';
import { loginController } from './auth.login.controller';
import { refreshController, logoutController } from './auth.refresh.controller';
import { authMiddleware } from '../../shared/middleware/auth.middleware';

const router = Router();

// POST /api/auth/register
router.post('/register', registerController);

// POST /api/auth/login
router.post('/login', loginController);

// POST /api/auth/refresh — renueva el access token usando el refresh token
// No requiere authMiddleware porque el access token puede haber vencido ya
router.post('/refresh', refreshController);

// POST /api/auth/logout — revoca todos los refresh tokens del usuario
// Requiere estar autenticado (el access token aún no venció)
router.post('/logout', authMiddleware, logoutController);

export default router;
