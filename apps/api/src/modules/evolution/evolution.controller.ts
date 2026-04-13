import type { Request, Response } from 'express';
import * as service from './evolution.service';

// POST /api/evolution/connect
// Inicia la vinculación del número de WhatsApp → devuelve QR base64.
export async function connectController(req: Request, res: Response): Promise<void> {
  try {
    const tenantId = req.user!.tenant_id;
    const result   = await service.connectWhatsApp(tenantId);
    res.json(result);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Error al conectar';
    res.status(400).json({ error: msg });
  }
}

// GET /api/evolution/status
// Devuelve el estado de conexión actual: disconnected | connecting | connected + phone.
export async function statusController(req: Request, res: Response): Promise<void> {
  try {
    const tenantId = req.user!.tenant_id;
    const result   = await service.getConnectionStatus(tenantId);
    res.json(result);
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Error al obtener estado';
    res.status(500).json({ error: msg });
  }
}

// DELETE /api/evolution/disconnect
// Desconecta el número y limpia el estado del tenant.
export async function disconnectController(req: Request, res: Response): Promise<void> {
  try {
    const tenantId = req.user!.tenant_id;
    await service.disconnectWhatsApp(tenantId);
    res.json({ ok: true });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Error al desconectar';
    res.status(500).json({ error: msg });
  }
}
