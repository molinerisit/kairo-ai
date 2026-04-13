import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import {
  listEventsController,
  getEventController,
  createEventController,
  updateEventController,
  deleteEventController,
} from './calendar.controller';

const router = Router();
router.use(authMiddleware);

// GET    /api/calendar?from=&to=&status=   → listar eventos con filtros opcionales
// POST   /api/calendar                     → crear evento
// GET    /api/calendar/:eventId            → detalle
// PATCH  /api/calendar/:eventId            → actualizar
// DELETE /api/calendar/:eventId            → eliminar

router.get ('/',           listEventsController);
router.post('/',           createEventController);
router.get ('/:eventId',   getEventController);
router.patch('/:eventId',  updateEventController);
router.delete('/:eventId', deleteEventController);

export default router;
