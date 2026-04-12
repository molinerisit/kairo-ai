import { Router } from 'express';
import { registerController } from './auth.controller';

// Router de Express: agrupa los endpoints de un módulo.
// Se monta en server.ts con un prefijo (/api/auth).
const router = Router();

// POST /api/auth/register
router.post('/register', registerController);

// POST /api/auth/login  ← se implementa en issue #3
// router.post('/login', loginController);

export default router;
