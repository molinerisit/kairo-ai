import { env } from '../../config/env';

// evolution.client.ts — cliente HTTP para Evolution API.
//
// Evolution API es un servidor self-hosted que gestiona conexiones de WhatsApp
// via Baileys (biblioteca open-source). Cada "instancia" es un número conectado.
//
// Usamos el slug del tenant como nombre de instancia → es único y permite
// identificar al tenant desde el webhook sin consultar la DB.

function headers() {
  return {
    'Content-Type': 'application/json',
    'apikey': env.EVOLUTION_API_KEY!,
  };
}

async function request<T>(method: string, path: string, body?: unknown): Promise<T> {
  const url = `${env.EVOLUTION_API_URL}${path}`;
  const res  = await fetch(url, {
    method,
    headers: headers(),
    body:    body ? JSON.stringify(body) : undefined,
  });

  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(`[Evolution] ${method} ${path} → ${res.status}: ${text}`);
  }

  return res.json() as Promise<T>;
}

// ── Tipos ─────────────────────────────────────────────────────────────────────

export interface InstanceStatus {
  state: 'open' | 'connecting' | 'close';
}

export interface QrResponse {
  code:  string;   // base64 de la imagen QR
  count: number;   // cuántas veces se regeneró
}

// ── Métodos ───────────────────────────────────────────────────────────────────

// createInstance: crea una nueva instancia para el tenant.
// instanceName = slug del tenant (único y derivable sin DB).
export async function createInstance(instanceName: string): Promise<void> {
  await request('POST', '/instance/create', {
    instanceName,
    integration: 'WHATSAPP-BAILEYS',
    qrcode:      true,
  });
}

// getQr: obtiene el QR code actual para que el usuario lo escanee.
// Devuelve null si la instancia no existe o ya está conectada.
export async function getQr(instanceName: string): Promise<QrResponse | null> {
  try {
    return await request<QrResponse>('GET', `/instance/connect/${instanceName}`);
  } catch {
    return null;
  }
}

// getStatus: devuelve el estado de conexión de la instancia.
export async function getStatus(instanceName: string): Promise<InstanceStatus | null> {
  try {
    const res = await request<{ instance: InstanceStatus }>(
      'GET', `/instance/connectionState/${instanceName}`
    );
    return res.instance;
  } catch {
    return null;
  }
}

// logout: desconecta el número sin eliminar la instancia.
export async function logout(instanceName: string): Promise<void> {
  await request('DELETE', `/instance/logout/${instanceName}`);
}

// deleteInstance: elimina completamente la instancia.
export async function deleteInstance(instanceName: string): Promise<void> {
  await request('DELETE', `/instance/delete/${instanceName}`);
}

// sendText: envía un mensaje de texto a un número vía la instancia conectada.
// `to` es el número completo sin +, ej: "5491112345678"
export async function sendText(instanceName: string, to: string, text: string): Promise<void> {
  await request('POST', `/message/sendText/${instanceName}`, {
    number: to,
    text,
  });
}
