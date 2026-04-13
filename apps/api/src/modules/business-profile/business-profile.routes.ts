import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import { getProfileController, updateProfileController } from './business-profile.controller';

const router = Router();

// Todos los endpoints del perfil requieren autenticación
router.use(authMiddleware);

router.get('/',   getProfileController);
router.patch('/', updateProfileController);

export default router;
