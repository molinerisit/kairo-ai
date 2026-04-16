import { query } from '../../shared/db/pool';

const GRAPH = 'https://graph.facebook.com/v21.0';

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

// ── GET AVAILABLE ACCOUNTS ────────────────────────────────────────────────────
// Recibe el access_token del usuario (desde FB.login en el frontend).
// Devuelve todos los números de WhatsApp accesibles en sus WABAs.

export async function getAvailableAccounts(accessToken: string): Promise<PhoneNumberOption[]> {
  // 1. Obtener businesses del usuario
  const bizRes  = await graphGet('/me/businesses', accessToken, 'id,name,owned_whatsapp_business_accounts{id,name}');
  const bizData = bizRes as any;

  const numbers: PhoneNumberOption[] = [];

  const businesses: any[] = bizData?.data ?? [];

  for (const biz of businesses) {
    const wabas: any[] = biz.owned_whatsapp_business_accounts?.data ?? [];

    for (const waba of wabas) {
      // 2. Por cada WABA, traer sus números
      const phoneRes  = await graphGet(`/${waba.id}/phone_numbers`, accessToken, 'id,display_phone_number,verified_name');
      const phoneData = phoneRes as any;

      for (const phone of (phoneData?.data ?? [])) {
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

  return numbers;
}

// ── CONNECT ───────────────────────────────────────────────────────────────────
// Guarda la conexión elegida por el usuario y suscribe la app al WABA.

export async function connectWhatsApp(
  tenantId:      string,
  accessToken:   string,
  wabaId:        string,
  phoneNumberId: string,
): Promise<WhatsAppConnection> {
  // Traer el número de display
  const phoneRes  = await graphGet(`/${phoneNumberId}`, accessToken, 'display_phone_number');
  const displayPhone = (phoneRes as any)?.display_phone_number ?? null;

  // Suscribir la app al WABA para recibir webhooks de este tenant
  await subscribeAppToWaba(wabaId, accessToken);

  // Upsert: un tenant = una conexión activa
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
    [tenantId, wabaId, phoneNumberId, displayPhone, accessToken],
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
