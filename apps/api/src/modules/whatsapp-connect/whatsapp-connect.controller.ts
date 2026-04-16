import type { Request, Response } from 'express';
import {
  getAvailableAccounts,
  connectWhatsApp,
  getConnection,
  disconnectWhatsApp,
} from './whatsapp-connect.service';

// GET /api/whatsapp/accounts?access_token=xxx
// Recibe el token del usuario (obtenido por FB.login en el frontend).
// Devuelve la lista de WABAs y números disponibles para elegir.
export async function accountsController(req: Request, res: Response): Promise<void> {
  const accessToken = req.query['access_token'] as string;

  if (!accessToken) {
    res.status(400).json({ error: 'access_token requerido' });
    return;
  }

  try {
    const accounts = await getAvailableAccounts(accessToken);
    res.json({ accounts });
  } catch (err: any) {
    res.status(err.statusCode ?? 500).json({ error: err.message ?? 'Error interno' });
  }
}

// POST /api/whatsapp/connect
// El usuario ya eligió su número. Guarda la conexión.
// Body: { access_token, waba_id, phone_number_id }
export async function connectController(req: Request, res: Response): Promise<void> {
  const tenantId = req.user!.tenant_id;
  const { access_token, waba_id, phone_number_id } = req.body;

  if (!access_token || !waba_id || !phone_number_id) {
    res.status(400).json({ error: 'Faltan campos: access_token, waba_id, phone_number_id' });
    return;
  }

  try {
    const connection = await connectWhatsApp(tenantId, access_token, waba_id, phone_number_id);
    res.json({ connection });
  } catch (err: any) {
    res.status(err.statusCode ?? 500).json({ error: err.message ?? 'Error interno' });
  }
}

// GET /api/whatsapp/connection
export async function statusController(req: Request, res: Response): Promise<void> {
  const connection = await getConnection(req.user!.tenant_id);
  res.json({ connection: connection ?? null });
}

// DELETE /api/whatsapp/connection
export async function disconnectController(req: Request, res: Response): Promise<void> {
  await disconnectWhatsApp(req.user!.tenant_id);
  res.json({ ok: true });
}
