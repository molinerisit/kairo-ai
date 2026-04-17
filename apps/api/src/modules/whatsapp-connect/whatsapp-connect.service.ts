import { randomUUID } from 'crypto';
import { query } from '../../shared/db/pool';
import { env } from '../../config/env';

const GRAPH = 'https://graph.facebook.com/v21.0';
const SESSION_TTL_MS = 10 * 60 * 1000; // 10 minutos

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

// ── SESSION STORE (in-memory, single instance) ────────────────────────────────
// Guarda el access_token temporalmente entre el paso de picker y el de connect.
// El token nunca sale del backend hacia el cliente.

const sessionStore = new Map<string, { token: string; expiresAt: number }>();

function storeSession(token: string): string {
  const id = randomUUID();
  sessionStore.set(id, { token, expiresAt: Date.now() + SESSION_TTL_MS });
  return id;
}

function consumeSession(sessionId: string): string {
  const entry = sessionStore.get(sessionId);
  if (!entry) throw { statusCode: 400, message: 'Sesión expirada o inválida. Volvé a conectar con Meta.' };
  if (Date.now() > entry.expiresAt) {
    sessionStore.delete(sessionId);
    throw { statusCode: 400, message: 'Sesión expirada. Volvé a conectar con Meta.' };
  }
  sessionStore.delete(sessionId); // uso único
  return entry.token;
}

// ── GET AVAILABLE ACCOUNTS ────────────────────────────────────────────────────
// 1. Intercambia el code de OAuth por un access token (server-side, nunca al cliente)
// 2. Fetchea WABAs y números del usuario
// 3. Devuelve los números disponibles + un session_id para el paso de connect

export async function getAvailableAccounts(code: string): Promise<{
  accounts:   PhoneNumberOption[];
  session_id: string;
}> {
  const appId     = env.META_APP_ID;
  const appSecret = env.META_APP_SECRET;
  if (!appId || !appSecret) throw { statusCode: 500, message: 'META_APP_ID o META_APP_SECRET no configurados' };

  // 1. Intercambiar code por access token
  const token = await exchangeCode(code, appId, appSecret);

  // 2. Fetchear businesses → WABAs → números
  const bizRes = await graphGet('/me/businesses', token, 'id,name,owned_whatsapp_business_accounts{id,name}');
  const businesses: any[] = (bizRes as any)?.data ?? [];
  const numbers: PhoneNumberOption[] = [];

  for (const biz of businesses) {
    const wabas: any[] = biz.owned_whatsapp_business_accounts?.data ?? [];
    for (const waba of wabas) {
      const phoneRes = await graphGet(`/${waba.id}/phone_numbers`, token, 'id,display_phone_number,verified_name');
      for (const phone of (phoneRes as any)?.data ?? []) {
        numbers.push({
          phone_number_id:      phone.id,
          display_phone_number: phone.display_phone_number,
          verified_name:        phone.verified_name ?? biz.name,
          waba_id:              waba.id,
          waba_name:            waba.name ?? biz.name,
        });
      }
    }
  }

  // 3. Guardar token en sesión temporal (el cliente solo recibe el session_id)
  const session_id = storeSession(token);
  return { accounts: numbers, session_id };
}

// ── CONNECT ───────────────────────────────────────────────────────────────────
// Recupera el token por session_id, suscribe el WABA y guarda la conexión.

export async function connectWhatsApp(
  tenantId:      string,
  sessionId:     string,
  wabaId:        string,
  phoneNumberId: string,
): Promise<WhatsAppConnection> {
  const token = consumeSession(sessionId);

  const phoneRes   = await graphGet(`/${phoneNumberId}`, token, 'display_phone_number');
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
  const res  = await fetch(`${GRAPH}/oauth/access_token?${params}`);
  const data = await res.json() as { access_token?: string; error?: { message: string } };
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
