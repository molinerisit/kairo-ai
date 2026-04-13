import { Router } from 'express';
import { authMiddleware } from '../../shared/middleware/auth.middleware';
import {
  listTablesController,
  createTableController,
  getTableController,
  updateColumnsController,
  deleteTableController,
  listRowsController,
  createRowController,
  updateRowController,
  deleteRowController,
} from './tables.controller';

const router = Router();

// Todas las rutas de tablas requieren autenticación.
// router.use() aplica el middleware a TODAS las rutas de este router.
router.use(authMiddleware);

// ── Tablas ────────────────────────────────────────────────────────
// GET    /api/tables              → listar tablas del tenant
// POST   /api/tables              → crear tabla nueva
// GET    /api/tables/:tableId     → obtener tabla con columnas
// PUT    /api/tables/:tableId/columns → actualizar columnas
// DELETE /api/tables/:tableId     → eliminar tabla

router.get('/',                              listTablesController);
router.post('/',                             createTableController);
router.get('/:tableId',                      getTableController);
router.put('/:tableId/columns',              updateColumnsController);
router.delete('/:tableId',                   deleteTableController);

// ── Filas ─────────────────────────────────────────────────────────
// GET    /api/tables/:tableId/rows           → listar filas
// POST   /api/tables/:tableId/rows           → crear fila
// PUT    /api/tables/:tableId/rows/:rowId    → actualizar fila
// DELETE /api/tables/:tableId/rows/:rowId    → eliminar fila

router.get('/:tableId/rows',                 listRowsController);
router.post('/:tableId/rows',                createRowController);
router.put('/:tableId/rows/:rowId',          updateRowController);
router.delete('/:tableId/rows/:rowId',       deleteRowController);

export default router;
