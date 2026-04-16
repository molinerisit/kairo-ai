import { query } from '../../shared/db/pool';
import { env } from '../../config/env';

const GRAPH = 'https://graph.facebook.com/v21.0';

// ── TIPOS ─────────────────────────────────────────────────────────────────────

export interface WhatsAppConnection {
  id:               string;
  tenant_id:        string;
  waba_id:          string | null;
  phone_number_id:  string | null;
  phone_number:     string | null;
  status:           'pending' | 'active' | 'inactive' | 'error';
  created_at:       string;
  updated_at:       string;
}

export interface ConnectInput {
  code:            string;
  waba_id?:        string;
  phone_number_id?: string;
}

// ── CONNECT ───────────────────────────────────────────────────────────────────
// Flujo completo del Embedded Signup:
// 1. Intercambia el code de OAuth por un access token de Meta
// 2. Obtiene el WABA y phone_number_id si no vienen del frontend
// 3. Suscribe la app al WABA para recibir webhooks
// 4. Guarda la conexión en DB

export async function connectWhatsApp(
  tenantId: string,
  input: ConnectInput,
): Promise<WhatsAppConnection> {
  const appId     = env.META_APP_ID;
  const appSecret = env.META_APP_SECRET;

  if (!appId || !appSecret) {
    throw { statusCode: 500, message: 'META_APP_ID o META_APP_SECRET no configurados' };
  }

  // 1. Intercambiar code → access token de usuario
  const token = await exchangeCode(input.code, appId, appSecret);

  // 2. Resolver waba_id y phone_number_id
  let wabaId        = input.waba_id;
  let phoneNumberId = input.phone_number_id;
  let displayPhone: string | null = null;

  if (!wabaId || !phoneNumberId) {
    const resolved = await resolveWabaAndPhone(token, wabaId);
    wabaId        = resolved.wabaId;
    phoneNumberId = resolved.phoneNumberId;
    displayPhone  = resolved.displayPhone;
  } else {
    displayPhone = await getDisplayPhone(phoneNumberId, token);
  }

  // 3. Suscribir la app al WABA para recibir webhooks de este tenant
  await subscribeAppToWaba(wabaId, token);

  // 4. Upsert en DB (un tenant = una conexión)
  const result = await query<WhatsAppConnection>(
    `INSERT INTO whatsapp_connections
       (tenant_id, waba_id, phone_number_id, phone_number, access_token, status)
     VALUES ($1, $2, $3, $4, $5, 'active')
     ON CONFLICT (tenant_id) DO UPDATE SET
       waba_id        = EXCLUDED.waba_id,
       phone_number_id = EXCLUDED.phone_number_id,
       phone_number   = EXCLUDED.phone_number,
       access_token   = EXCLUDED.access_token,
       status         = 'active',
       updated_at     = now()
     RETURNING id, tenant_id, waba_id, phone_number_id, phone_number, status, created_at, updated_at`,
    [tenantId, wabaId, phoneNumberId, displayPhone, token],
  );

  return result.rows[0];
}

// ── STATUS ────────────────────────────────────────────────────────────────────

export async function getConnection(tenantId: string): Promise<WhatsAppConnection | null> {
  const result = await query<WhatsAppConnection>(
    `SELECT id, tenant_id, waba_id, phone_number_id, phone_number, status, created_at, updated_at
     FROM whatsapp_connections WHERE tenant_id = $1`,
    [tenantId],
  );
  return result.rows[0] ?? null;
}

// ── DISCONNECT ────────────────────────────────────────────────────────────────

export async function disconnectWhatsApp(tenantId: string): Promise<void> {
  await query(
    `UPDATE whatsapp_connections SET status = 'inactive', updated_at = now()
     WHERE tenant_id = $1`,
    [tenantId],
  );
}

// ── HELPERS META API ──────────────────────────────────────────────────────────

async function exchangeCode(code: string, appId: string, appSecret: string): Promise<string> {
  const url = `${GRAPH}/oauth/access_token?client_id=${appId}&client_secret=${appSecret}&code=${code}`;
  const res = await fetch(url);
  const data = await res.json() as { access_token?: string; error?: { message: string } };

  if (!res.ok || !data.access_token) {
    const msg = data.error?.message ?? 'Error intercambiando code de Meta';
    throw { statusCode: 400, message: msg };
  }

  return data.access_token;
}

async function resolveWabaAndPhone(token: string, wabaId?: string): Promise<{
  wabaId: string;
  phoneNumberId: string;
  displayPhone: string | null;
}> {
  // Obtener WABAs asociados al token de usuario
  if (!wabaId) {
    const res = await fetch(`${GRAPH}/me/businesses?fields=owned_whatsapp_business_accounts&access_token=${token}`);
    const data = await res.json() as any;
    wabaId = data?.data?.[0]?.owned_whatsapp_business_accounts?.data?.[0]?.id;
    if (!wabaId) throw { statusCode: 400, message: 'No se encontró ningún WABA asociado al token' };
  }

  // Obtener números de teléfono del WABA
  const res2 = await fetch(`${GRAPH}/${wabaId}/phone_numbers?fields=id,display_phone_number&access_token=${token}`);
  const data2 = await res2.json() as any;
  const phone = data2?.data?.[0];
  if (!phone) throw { statusCode: 400, message: 'No se encontró ningún número en el WABA' };

  return {
    wabaId,
    phoneNumberId: phone.id,
    displayPhone:  phone.display_phone_number ?? null,
  };
}

async function getDisplayPhone(phoneNumberId: string, token: string): Promise<string | null> {
  const res = await fetch(`${GRAPH}/${phoneNumberId}?fields=display_phone_number&access_token=${token}`);
  const data = await res.json() as any;
  return data?.display_phone_number ?? null;
}

async function subscribeAppToWaba(wabaId: string, token: string): Promise<void> {
  const res = await fetch(`${GRAPH}/${wabaId}/subscribed_apps`, {
    method:  'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const data = await res.json() as any;
    console.warn('[WhatsApp Connect] No se pudo suscribir al WABA:', data?.error?.message);
  }
}
