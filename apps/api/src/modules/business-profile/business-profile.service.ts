import { query, getClient } from '../../shared/db/pool';
import type { BusinessProfile } from './business-profile.types';
import type { UpdateBusinessProfileInput } from './business-profile.schema';

// GET: une business_profiles con tenants para devolver el nombre del negocio también
export async function getBusinessProfile(tenantId: string): Promise<BusinessProfile | null> {
  const result = await query<BusinessProfile & { name: string }>(
    `SELECT bp.id, bp.tenant_id, t.name,
            bp.tone, bp.description, bp.address, bp.whatsapp,
            bp.hours, bp.services, bp.faqs, bp.updated_at
     FROM business_profiles bp
     JOIN tenants t ON t.id = bp.tenant_id
     WHERE bp.tenant_id = $1`,
    [tenantId]
  );
  return result.rows[0] ?? null;
}

// PATCH: actualiza business_profiles y opcionalmente el nombre en tenants
export async function updateBusinessProfile(
  tenantId: string,
  input: UpdateBusinessProfileInput
): Promise<BusinessProfile | null> {
  const client = await getClient();
  try {
    await client.query('BEGIN');

    // Actualizar tenants.name si viene en el input
    if (input.name !== undefined) {
      await client.query(
        `UPDATE tenants SET name = $1 WHERE id = $2`,
        [input.name, tenantId]
      );
    }

    // Construir SET dinámico para business_profiles
    const fields: string[] = ['updated_at = now()'];
    const values: unknown[] = [];
    let idx = 1;

    if (input.tone        !== undefined) { fields.push(`tone = $${idx++}`);        values.push(input.tone); }
    if (input.description !== undefined) { fields.push(`description = $${idx++}`); values.push(input.description); }
    if (input.address     !== undefined) { fields.push(`address = $${idx++}`);     values.push(input.address); }
    if (input.whatsapp    !== undefined) { fields.push(`whatsapp = $${idx++}`);    values.push(input.whatsapp); }
    if (input.hours       !== undefined) { fields.push(`hours = $${idx++}`);       values.push(JSON.stringify(input.hours)); }
    if (input.services    !== undefined) { fields.push(`services = $${idx++}`);    values.push(JSON.stringify(input.services)); }
    if (input.faqs        !== undefined) { fields.push(`faqs = $${idx++}`);        values.push(JSON.stringify(input.faqs)); }

    values.push(tenantId);
    await client.query(
      `UPDATE business_profiles SET ${fields.join(', ')} WHERE tenant_id = $${idx}`,
      values
    );

    await client.query('COMMIT');
    return getBusinessProfile(tenantId);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
