import { query } from '../../shared/db/pool';
import { env } from '../../config/env';

const GRAPH = 'https://graph.facebook.com/v21.0';
const SESSION_TTL_MS = 10 * 60 * 1000;

// ── TIPOS ─────────────────────────────────────────────────────────────────────

export interface WhatsAppConnection {
  id:              string;
  tenant_id:       string;
  waba_id:         string | null;
  phone_number_id: string | null;
  phone_number:    string | null;
  status:          'pending' | 'active' | 'inactive' | 'error';
  created_at:      string;
  updated_at:      string;
}

export interface PhoneNumberOption {
  phone_number_id:      string;
  display_phone_number: string;
  verified_name:        string;
  waba_id:              string;
  waba_name:            string;
}

// ── SESSION STORE ─────────────────────────────────────────────────────────────
// El code de OAuth actúa como session key — nunca sale del servidor hacia el cliente.

const sessionStore = new Map<string, { token: string; expiresAt: number }>();

function storeSession(code: string, token: string): void {
  sessionStore.set(code, { token, expiresAt: Date.now() + SESSION_TTL_MS });
}

function consumeSession(code: string): string {
  const entry = sessionStore.get(code);
  if (!entry) throw { statusCode: 400, message: 'Sesión expirada o inválida. Volvé a conectar con Meta.' };
  if (Date.now() > entry.expiresAt) {
    sessionStore.delete(code);
    throw { statusCode: 400, message: 'Sesión expirada. Volvé a conectar con Meta.' };
  }
  sessionStore.delete(code);
  return entry.token;
}

// ── GET AVAILABLE ACCOUNTS ────────────────────────────────────────────────────
// 1. Intercambia el code por access_token (server-side, nunca al cliente)
// 2. Descubre WABAs vía /me/whatsapp_business_accounts (no requiere App Review)
// 3. Devuelve los números disponibles

export async function getAvailableAccounts(code: string): Promise<{ accounts: PhoneNumberOption[] }> {
  const appId     = env.META_APP_ID;
  const appSecret = env.META_APP_SECRET;
  if (!appId || !appSecret) throw { statusCode: 500, message: 'META_APP_ID o META_APP_SECRET no configurados' };

  const token = await exchangeCode(code, appId, appSecret);
  storeSession(code, token);

  // Descubre WABAs a los que el usuario dio acceso durante el Embedded Signup
  const wabaRes = await graphGet('/me/whatsapp_business_accounts', token, 'id,name');
  console.log('[WhatsApp] /me/whatsapp_business_accounts →', JSON.stringify(wabaRes));

  const wabas: any[] = (wabaRes as any)?.data ?? [];
  const numbers: PhoneNumberOption[] = [];

  for (const waba of wabas) {
    const phoneRes = await graphGet(`/${waba.id}/phone_numbers`, token, 'id,display_phone_number,verified_name');
    console.log(`[WhatsApp] /${waba.id}/phone_numbers →`, JSON.stringify(phoneRes));
    for (const phone of (phoneRes as any)?.data ?? []) {
      numbers.push({
        phone_number_id:      phone.id,
        display_phone_number: phone.display_phone_number,
        verified_name:        phone.verified_name ?? waba.name,
        waba_id:              waba.id,
        waba_name:            waba.name,
      });
    }
  }

  console.log('[WhatsApp] números encontrados:', numbers.length);
  return { accounts: numbers };
}

// ── CONNECT ───────────────────────────────────────────────────────────────────
// Recupera el token por code, suscribe el WABA y guarda la conexión.

export async function connectWhatsApp(
  tenantId:      string,
  code:          string,
  wabaId:        string,
  phoneNumberId: string,
): Promise<WhatsAppConnection> {
  const token = consumeSession(code);

  const phoneRes    = await graphGet(`/${phoneNumberId}`, token, 'display_phone_number');
  const displayPhone = (phoneRes as any)?.display_phone_number ?? null;

  await subscribeAppToWaba(wabaId, token);

  const result = await query<WhatsAppConnection>(
    `INSERT INTO whatsapp_connections
       (tenant_id, waba_id, phone_number_id, phone_number, access_token, status)
     VALUES ($1, $2, $3, $4, $5, 'active')
     ON CONFLICT (tenant_id) DO UPDATE SET
       waba_id         = EXCLUDED.waba_id,
       phone_number_id = EXCLUDED.phone_number_id,
       phone_number    = EXCLUDED.phone_number,
       access_token    = EXCLUDED.access_token,
       status          = 'active',
       updated_at      = now()
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
    `UPDATE whatsapp_connections SET status = 'inactive', updated_at = now() WHERE tenant_id = $1`,
    [tenantId],
  );
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

async function exchangeCode(code: string, appId: string, appSecret: string): Promise<string> {
  const params = new URLSearchParams({ client_id: appId, client_secret: appSecret, code });
  const url = `${GRAPH}/oauth/access_token?${params}`;
  console.log('[WhatsApp] exchangeCode → POST', url.replace(appSecret, '***'));

  const res  = await fetch(url);
  const data = await res.json() as { access_token?: string; error?: { message: string } };
  console.log('[WhatsApp] exchangeCode ← status:', res.status, 'body:', JSON.stringify(data));

  if (!res.ok || !data.access_token) {
    throw { statusCode: 400, message: data.error?.message ?? 'Error al intercambiar el code con Meta' };
  }
  return data.access_token;
}

async function graphGet(path: string, token: string, fields?: string): Promise<unknown> {
  const params = new URLSearchParams({ access_token: token });
  if (fields) params.set('fields', fields);
  const res = await fetch(`${GRAPH}${path}?${params}`);
  return res.json();
}

async function subscribeAppToWaba(wabaId: string, token: string): Promise<void> {
  const res = await fetch(`${GRAPH}/${wabaId}/subscribed_apps`, {
    method:  'POST',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const data = await res.json() as any;
    console.warn('[WhatsApp] No se pudo suscribir al WABA:', data?.error?.message);
  }
}
