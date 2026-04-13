import { query } from '../../shared/db/pool';
import type { CalendarEvent } from './calendar.types';
import type { CreateEventInput, UpdateEventInput, ListEventsFilters } from './calendar.schema';

export async function listEvents(
  tenantId: string,
  filters: ListEventsFilters = {}
): Promise<CalendarEvent[]> {
  // Construimos la query dinámicamente según los filtros que vienen
  const conditions: string[] = ['tenant_id = $1'];
  const values: unknown[]    = [tenantId];
  let idx = 2;

  if (filters.from) {
    conditions.push(`starts_at >= $${idx++}`);
    values.push(filters.from);
  }
  if (filters.to) {
    conditions.push(`starts_at <= $${idx++}`);
    values.push(filters.to);
  }
  if (filters.status) {
    conditions.push(`status = $${idx++}`);
    values.push(filters.status);
  }

  const result = await query<CalendarEvent>(
    `SELECT id, tenant_id, title, description, starts_at, ends_at,
            status, contact_data, metadata, created_at, updated_at
     FROM calendar_events
     WHERE ${conditions.join(' AND ')}
     ORDER BY starts_at ASC`,
    values
  );
  return result.rows;
}

export async function getEvent(tenantId: string, eventId: string): Promise<CalendarEvent | null> {
  const result = await query<CalendarEvent>(
    `SELECT id, tenant_id, title, description, starts_at, ends_at,
            status, contact_data, metadata, created_at, updated_at
     FROM calendar_events
     WHERE id = $1 AND tenant_id = $2`,
    [eventId, tenantId]
  );
  return result.rows[0] ?? null;
}

export async function createEvent(tenantId: string, input: CreateEventInput): Promise<CalendarEvent> {
  const result = await query<CalendarEvent>(
    `INSERT INTO calendar_events
       (tenant_id, title, description, starts_at, ends_at, contact_data, metadata)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING id, tenant_id, title, description, starts_at, ends_at,
               status, contact_data, metadata, created_at, updated_at`,
    [
      tenantId,
      input.title,
      input.description ?? null,
      input.starts_at,
      input.ends_at,
      JSON.stringify(input.contact_data),
      JSON.stringify(input.metadata),
    ]
  );
  return result.rows[0];
}

export async function updateEvent(
  tenantId: string,
  eventId: string,
  input: UpdateEventInput
): Promise<CalendarEvent | null> {
  const fields: string[] = [];
  const values: unknown[] = [];
  let idx = 1;

  if (input.title        !== undefined) { fields.push(`title = $${idx++}`);        values.push(input.title); }
  if (input.description  !== undefined) { fields.push(`description = $${idx++}`);  values.push(input.description); }
  if (input.starts_at    !== undefined) { fields.push(`starts_at = $${idx++}`);    values.push(input.starts_at); }
  if (input.ends_at      !== undefined) { fields.push(`ends_at = $${idx++}`);      values.push(input.ends_at); }
  if (input.status       !== undefined) { fields.push(`status = $${idx++}`);       values.push(input.status); }
  if (input.contact_data !== undefined) { fields.push(`contact_data = $${idx++}`); values.push(JSON.stringify(input.contact_data)); }
  if (input.metadata     !== undefined) { fields.push(`metadata = $${idx++}`);     values.push(JSON.stringify(input.metadata)); }

  if (fields.length === 0) return getEvent(tenantId, eventId);

  values.push(eventId, tenantId);
  const result = await query<CalendarEvent>(
    `UPDATE calendar_events
     SET ${fields.join(', ')}
     WHERE id = $${idx++} AND tenant_id = $${idx}
     RETURNING id, tenant_id, title, description, starts_at, ends_at,
               status, contact_data, metadata, created_at, updated_at`,
    values
  );
  return result.rows[0] ?? null;
}

export async function deleteEvent(tenantId: string, eventId: string): Promise<boolean> {
  const result = await query(
    `DELETE FROM calendar_events WHERE id = $1 AND tenant_id = $2`,
    [eventId, tenantId]
  );
  return (result.rowCount ?? 0) > 0;
}
