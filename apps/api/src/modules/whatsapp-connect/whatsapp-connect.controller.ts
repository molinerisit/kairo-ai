import type { Request, Response } from 'express';
import {
  connectWhatsApp,
  getConnection,
  disconnectWhatsApp,
} from './whatsapp-connect.service';

// POST /api/whatsapp/connect
// Recibe el code del Embedded Signup de Meta y completa la vinculación.
// Body: { code, waba_id?, phone_number_id? }
export async function connectController(req: Request, res: Response): Promise<void> {
  const tenantId = req.user!.tenant_id;
  const { code, waba_id, phone_number_id } = req.body;

  if (!code) {
    res.status(400).json({ error: 'El campo code es requerido' });
    return;
  }

  try {
    const connection = await connectWhatsApp(tenantId, { code, waba_id, phone_number_id });
    res.status(200).json({ connection });
  } catch (err: any) {
    const status  = err.statusCode ?? 500;
    const message = err.message   ?? 'Error interno';
    res.status(status).json({ error: message });
  }
}

// GET /api/whatsapp/connection
// Devuelve el estado de la conexión de WhatsApp del tenant.
export async function statusController(req: Request, res: Response): Promise<void> {
  const tenantId = req.user!.tenant_id;
  const connection = await getConnection(tenantId);
  res.json({ connection: connection ?? null });
}

// DELETE /api/whatsapp/connection
// Desconecta el número de WhatsApp del tenant (marca como inactive).
export async function disconnectController(req: Request, res: Response): Promise<void> {
  const tenantId = req.user!.tenant_id;
  await disconnectWhatsApp(tenantId);
  res.json({ ok: true });
}
