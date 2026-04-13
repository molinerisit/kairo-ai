import { query } from '../../shared/db/pool';
import * as evo from './evolution.client';

// evolution.service.ts — lógica de negocio para gestión de instancias WhatsApp.
//
// El nombre de instancia en Evolution API siempre es el slug del tenant.
// Esto permite identificar al tenant desde el webhook sin consultar la DB
// (el slug viene en el campo "instance" de cada evento).

// getTenantSlug: obtiene el slug del tenant a partir del tenant_id.
async function getTenantSlug(tenantId: string): Promise<string> {
  const res = await query<{ slug: string }>(
    'SELECT slug FROM tenants WHERE id = $1',
    [tenantId]
  );
  if (!res.rows[0]) throw new Error('Tenant no encontrado');
  return res.rows[0].slug;
}

// ── Conexión ──────────────────────────────────────────────────────────────────

// connectWhatsApp: inicia el proceso de vinculación del número.
// Si la instancia no existe en Evolution API, la crea.
// Devuelve el QR code (base64) para que el usuario lo escanee.
export async function connectWhatsApp(tenantId: string): Promise<{ qr: string }> {
  const slug   = await getTenantSlug(tenantId);
  const status = await evo.getStatus(slug);

  // Si ya está conectado, no hace falta mostrar QR
  if (status?.state === 'open') {
    throw new Error('El número ya está conectado. Desconectalo primero para vincular otro.');
  }

  // Si no existe, crear la instancia
  if (!status) {
    await evo.createInstance(slug);
  }

  // Actualizar estado en DB
  await query(
    `UPDATE business_profiles SET whatsapp_status = 'connecting' WHERE tenant_id = $1`,
    [tenantId]
  );

  // Obtener QR — Evolution lo genera de forma asíncrona, hay que reintentar
  const qr = await pollForQr(slug);
  if (!qr) throw new Error('No se pudo obtener el QR. Intentá de nuevo en unos segundos.');

  return { qr };
}

// getConnectionStatus: devuelve el estado actual de la instancia.
export async function getConnectionStatus(tenantId: string): Promise<{
  status: 'disconnected' | 'connecting' | 'connected';
  phone: string | null;
}> {
  const slug = await getTenantSlug(tenantId);
  const evoStatus = await evo.getStatus(slug);

  const dbRes = await query<{ whatsapp_status: string; whatsapp: string | null }>(
    'SELECT whatsapp_status, whatsapp FROM business_profiles WHERE tenant_id = $1',
    [tenantId]
  );

  const dbStatus  = dbRes.rows[0]?.whatsapp_status ?? 'disconnected';
  const phone     = dbRes.rows[0]?.whatsapp ?? null;

  // Sincronizar con Evolution API si hay discrepancia
  if (evoStatus?.state === 'open' && dbStatus !== 'connected') {
    await query(
      `UPDATE business_profiles SET whatsapp_status = 'connected' WHERE tenant_id = $1`,
      [tenantId]
    );
    return { status: 'connected', phone };
  }

  if ((!evoStatus || evoStatus.state === 'close') && dbStatus !== 'disconnected') {
    await query(
      `UPDATE business_profiles SET whatsapp_status = 'disconnected' WHERE tenant_id = $1`,
      [tenantId]
    );
    return { status: 'disconnected', phone: null };
  }

  return {
    status: dbStatus as 'disconnected' | 'connecting' | 'connected',
    phone,
  };
}

// disconnectWhatsApp: desconecta el número y limpia el estado.
export async function disconnectWhatsApp(tenantId: string): Promise<void> {
  const slug = await getTenantSlug(tenantId);
  await evo.logout(slug).catch(() => {}); // best-effort
  await query(
    `UPDATE business_profiles
     SET whatsapp_status = 'disconnected', whatsapp = NULL
     WHERE tenant_id = $1`,
    [tenantId]
  );
}

// ── Llamado desde el webhook ───────────────────────────────────────────────────

// onConnected: llamado cuando Evolution notifica que la instancia se conectó.
// Actualiza el estado en DB y guarda el número de teléfono.
export async function onConnected(slug: string, phone: string): Promise<void> {
  await query(
    `UPDATE business_profiles
     SET whatsapp_status = 'connected', whatsapp = $1
     WHERE tenant_id = (SELECT id FROM tenants WHERE slug = $2)`,
    [phone, slug]
  );
}

// onDisconnected: llamado cuando Evolution notifica desconexión.
export async function onDisconnected(slug: string): Promise<void> {
  await query(
    `UPDATE business_profiles
     SET whatsapp_status = 'disconnected'
     WHERE tenant_id = (SELECT id FROM tenants WHERE slug = $1)`,
    [slug]
  );
}

// pollForQr: reintenta obtener el QR hasta 10 veces con 1s de pausa entre intentos.
// Evolution API genera el QR de forma asíncrona después de crear/reconectar la instancia.
async function pollForQr(slug: string): Promise<string | null> {
  for (let i = 0; i < 10; i++) {
    const qrData = await evo.getQr(slug);
    if (qrData?.code) return qrData.code;
    await new Promise(r => setTimeout(r, 1000));
  }
  return null;
}

// getTenantIdBySlug: usado por el webhook para rutear mensajes al tenant correcto.
export async function getTenantIdBySlug(slug: string): Promise<string | null> {
  const res = await query<{ id: string }>(
    'SELECT id FROM tenants WHERE slug = $1',
    [slug]
  );
  return res.rows[0]?.id ?? null;
}
