import type { Request, Response } from 'express';
import {
  createTableSchema,
  updateColumnsSchema,
  upsertRowSchema,
} from './tables.schema';
import * as tablesService from './tables.service';

// Helper: extrae tenant_id del usuario autenticado.
// req.user siempre existe en rutas protegidas por authMiddleware.
function tenantId(req: Request): string {
  return req.user!.tenant_id;
}

// Helper: extrae un parámetro de ruta como string.
// En Express 5 los params se tipan como string | string[].
const param = (req: Request, name: string): string => String(req.params[name]);

// Helper reutilizable para manejar errores de negocio y errores inesperados
function handleError(res: Response, err: unknown): void {
  if (isAppError(err)) {
    res.status(err.statusCode).json({ error: err.message });
    return;
  }
  console.error('[Tables]', err);
  res.status(500).json({ error: 'Error interno del servidor' });
}

function isAppError(err: unknown): err is { statusCode: number; message: string } {
  return typeof err === 'object' && err !== null && 'statusCode' in err && 'message' in err;
}

// ── TABLAS ────────────────────────────────────────────────────────

export async function listTablesController(req: Request, res: Response): Promise<void> {
  try {
    const tables = await tablesService.listTables(tenantId(req));
    res.json(tables);
  } catch (err) { handleError(res, err); }
}

export async function createTableController(req: Request, res: Response): Promise<void> {
  const parsed = createTableSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }
  try {
    const table = await tablesService.createTable(tenantId(req), parsed.data);
    res.status(201).json(table);
  } catch (err) { handleError(res, err); }
}

export async function getTableController(req: Request, res: Response): Promise<void> {
  try {
    const table = await tablesService.getTable(tenantId(req), param(req, 'tableId'));
    if (!table) { res.status(404).json({ error: 'Tabla no encontrada' }); return; }
    res.json(table);
  } catch (err) { handleError(res, err); }
}

export async function updateColumnsController(req: Request, res: Response): Promise<void> {
  const parsed = updateColumnsSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }
  try {
    const table = await tablesService.updateColumns(tenantId(req), param(req, 'tableId'), parsed.data);
    if (!table) { res.status(404).json({ error: 'Tabla no encontrada' }); return; }
    res.json(table);
  } catch (err) { handleError(res, err); }
}

export async function deleteTableController(req: Request, res: Response): Promise<void> {
  try {
    const deleted = await tablesService.deleteTable(tenantId(req), param(req, 'tableId'));
    if (!deleted) { res.status(404).json({ error: 'Tabla no encontrada' }); return; }
    res.status(204).send();
  } catch (err) { handleError(res, err); }
}

// ── FILAS ─────────────────────────────────────────────────────────

export async function listRowsController(req: Request, res: Response): Promise<void> {
  try {
    const limit  = Math.min(parseInt(req.query.limit  as string) || 100, 500);
    const offset = parseInt(req.query.offset as string) || 0;
    const rows = await tablesService.listRows(tenantId(req), param(req, 'tableId'), limit, offset);
    res.json(rows);
  } catch (err) { handleError(res, err); }
}

export async function createRowController(req: Request, res: Response): Promise<void> {
  const parsed = upsertRowSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }
  try {
    const row = await tablesService.createRow(tenantId(req), param(req, 'tableId'), parsed.data);
    res.status(201).json(row);
  } catch (err) { handleError(res, err); }
}

export async function updateRowController(req: Request, res: Response): Promise<void> {
  const parsed = upsertRowSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }
  try {
    const row = await tablesService.updateRow(tenantId(req), param(req, 'tableId'), param(req, 'rowId'), parsed.data);
    if (!row) { res.status(404).json({ error: 'Fila no encontrada' }); return; }
    res.json(row);
  } catch (err) { handleError(res, err); }
}

export async function deleteRowController(req: Request, res: Response): Promise<void> {
  try {
    const deleted = await tablesService.deleteRow(tenantId(req), param(req, 'tableId'), param(req, 'rowId'));
    if (!deleted) { res.status(404).json({ error: 'Fila no encontrada' }); return; }
    res.status(204).send();
  } catch (err) { handleError(res, err); }
}
