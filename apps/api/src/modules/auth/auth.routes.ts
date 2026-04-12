import { Router } from 'express';
import { registerController } from './auth.controller';
import { loginController } from './auth.login.controller';

// Router de Express: agrupa los endpoints de un módulo.
// Se monta en server.ts con un prefijo (/api/auth).
const router = Router();

// POST /api/auth/register
router.post('/register', registerController);

// POST /api/auth/login
router.post('/login', loginController);

export default router;
