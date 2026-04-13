import type { Request, Response } from 'express';
import { createEventSchema, updateEventSchema, listEventsSchema } from './calendar.schema';
import * as service from './calendar.service';

const tenantId = (req: Request) => req.user!.tenant_id;
const param    = (req: Request, name: string) => String(req.params[name]);

function handleError(res: Response, err: unknown): void {
  if (isAppError(err)) { res.status(err.statusCode).json({ error: err.message }); return; }
  console.error('[Calendar]', err);
  res.status(500).json({ error: 'Error interno del servidor' });
}

function isAppError(err: unknown): err is { statusCode: number; message: string } {
  return typeof err === 'object' && err !== null && 'statusCode' in err && 'message' in err;
}

export async function listEventsController(req: Request, res: Response): Promise<void> {
  const parsed = listEventsSchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({ error: 'Parámetros inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }
  try {
    const events = await service.listEvents(tenantId(req), parsed.data);
    res.json(events);
  } catch (err) { handleError(res, err); }
}

export async function getEventController(req: Request, res: Response): Promise<void> {
  try {
    const event = await service.getEvent(tenantId(req), param(req, 'eventId'));
    if (!event) { res.status(404).json({ error: 'Evento no encontrado' }); return; }
    res.json(event);
  } catch (err) { handleError(res, err); }
}

export async function createEventController(req: Request, res: Response): Promise<void> {
  const parsed = createEventSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }
  try {
    const event = await service.createEvent(tenantId(req), parsed.data);
    res.status(201).json(event);
  } catch (err) { handleError(res, err); }
}

export async function updateEventController(req: Request, res: Response): Promise<void> {
  const parsed = updateEventSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten().fieldErrors });
    return;
  }
  try {
    const event = await service.updateEvent(tenantId(req), param(req, 'eventId'), parsed.data);
    if (!event) { res.status(404).json({ error: 'Evento no encontrado' }); return; }
    res.json(event);
  } catch (err) { handleError(res, err); }
}

export async function deleteEventController(req: Request, res: Response): Promise<void> {
  try {
    const deleted = await service.deleteEvent(tenantId(req), param(req, 'eventId'));
    if (!deleted) { res.status(404).json({ error: 'Evento no encontrado' }); return; }
    res.status(204).send();
  } catch (err) { handleError(res, err); }
}
