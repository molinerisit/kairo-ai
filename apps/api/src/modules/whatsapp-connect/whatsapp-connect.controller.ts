import type { Request, Response } from 'express';
import {
  getAvailableAccounts,
  connectWhatsApp,
  getConnection,
  disconnectWhatsApp,
} from './whatsapp-connect.service';

// POST /api/whatsapp/accounts
// Body: { code }
// El frontend manda el code de OAuth. El backend lo intercambia por un token,
// fetchea los números disponibles y devuelve { accounts, session_id }.
// El access_token nunca sale del servidor.
export async function accountsController(req: Request, res: Response): Promise<void> {
  const { code } = req.body;

  if (!code) {
    res.status(400).json({ error: 'El campo code es requerido' });
    return;
  }

  try {
    const result = await getAvailableAccounts(code);
    res.json(result);
  } catch (err: any) {
    console.error('[WhatsApp] accountsController error:', err);
    res.status(err.statusCode ?? 500).json({ error: err.message ?? 'Error interno' });
  }
}

// POST /api/whatsapp/connect
// Body: { session_id, waba_id, phone_number_id }
export async function connectController(req: Request, res: Response): Promise<void> {
  const tenantId = req.user!.tenant_id;
  const { session_id, waba_id, phone_number_id } = req.body;

  if (!session_id || !waba_id || !phone_number_id) {
    res.status(400).json({ error: 'Faltan campos: session_id, waba_id, phone_number_id' });
    return;
  }

  try {
    const connection = await connectWhatsApp(tenantId, session_id, waba_id, phone_number_id);
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
