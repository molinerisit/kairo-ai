import { query, pool } from '../../shared/db/pool';
import type { CreateTableInput, UpdateColumnsInput, UpsertRowInput } from './tables.schema';
import type { DynamicTable, DynamicRow, ColumnDefinition } from './tables.types';

// ── TABLAS ────────────────────────────────────────────────────────

// Listar todas las tablas del tenant
export async function listTables(tenantId: string): Promise<DynamicTable[]> {
  const result = await query<DynamicTable>(
    `SELECT id, tenant_id, name, table_type, columns, created_at
     FROM dynamic_tables
     WHERE tenant_id = $1
     ORDER BY created_at ASC`,
    [tenantId]
  );
  return result.rows;
}

// Crear una tabla nueva con su definición de columnas
export async function createTable(
  tenantId: string,
  input: CreateTableInput
): Promise<DynamicTable> {
  const result = await query<DynamicTable>(
    `INSERT INTO dynamic_tables (tenant_id, name, table_type, columns)
     VALUES ($1, $2, $3, $4)
     RETURNING id, tenant_id, name, table_type, columns, created_at`,
    [tenantId, input.name, input.table_type, JSON.stringify(input.columns)]
  );
  return result.rows[0];
}

// Obtener una tabla por id (verificando que pertenezca al tenant)
export async function getTable(
  tenantId: string,
  tableId: string
): Promise<DynamicTable | null> {
  const result = await query<DynamicTable>(
    `SELECT id, tenant_id, name, table_type, columns, created_at
     FROM dynamic_tables
     WHERE id = $1 AND tenant_id = $2`,
    [tableId, tenantId]
  );
  return result.rows[0] ?? null;
}

// Actualizar las columnas de una tabla
// Reemplaza la definición completa de columnas.
// Los datos existentes en las filas no se pierden — JSONB los mantiene.
export async function updateColumns(
  tenantId: string,
  tableId: string,
  input: UpdateColumnsInput
): Promise<DynamicTable | null> {
  const result = await query<DynamicTable>(
    `UPDATE dynamic_tables
     SET columns = $1
     WHERE id = $2 AND tenant_id = $3
     RETURNING id, tenant_id, name, table_type, columns, created_at`,
    [JSON.stringify(input.columns), tableId, tenantId]
  );
  return result.rows[0] ?? null;
}

// Eliminar una tabla y todas sus filas (CASCADE en el schema SQL)
export async function deleteTable(
  tenantId: string,
  tableId: string
): Promise<boolean> {
  const result = await query(
    `DELETE FROM dynamic_tables WHERE id = $1 AND tenant_id = $2`,
    [tableId, tenantId]
  );
  // rowCount > 0 significa que se eliminó algo
  return (result.rowCount ?? 0) > 0;
}

// ── FILAS ─────────────────────────────────────────────────────────

// Listar filas de una tabla con paginación básica
export async function listRows(
  tenantId: string,
  tableId: string,
  limit = 100,
  offset = 0
): Promise<DynamicRow[]> {
  const result = await query<DynamicRow>(
    `SELECT id, tenant_id, table_id, data, created_at, updated_at
     FROM dynamic_rows
     WHERE table_id = $1 AND tenant_id = $2
     ORDER BY created_at ASC
     LIMIT $3 OFFSET $4`,
    [tableId, tenantId, limit, offset]
  );
  return result.rows;
}

// Crear una fila nueva, validando que las columnas requeridas estén presentes
export async function createRow(
  tenantId: string,
  tableId: string,
  input: UpsertRowInput
): Promise<DynamicRow> {
  // Antes de insertar, verificamos que la tabla exista y sea del tenant
  const table = await getTable(tenantId, tableId);
  if (!table) {
    throw { statusCode: 404, message: 'Tabla no encontrada' };
  }

  // Validar columnas requeridas
  validateRequiredColumns(table.columns, input.data);

  const result = await query<DynamicRow>(
    `INSERT INTO dynamic_rows (tenant_id, table_id, data)
     VALUES ($1, $2, $3)
     RETURNING id, tenant_id, table_id, data, created_at, updated_at`,
    [tenantId, tableId, JSON.stringify(input.data)]
  );
  return result.rows[0];
}

// Actualizar los datos de una fila
// Usamos jsonb_merge para hacer merge: solo actualiza los campos que vienen,
// sin borrar los que no están en el input.
export async function updateRow(
  tenantId: string,
  tableId: string,
  rowId: string,
  input: UpsertRowInput
): Promise<DynamicRow | null> {
  const client = await pool.connect();
  try {
    // Verificar que la tabla existe antes de actualizar
    const table = await getTable(tenantId, tableId);
    if (!table) throw { statusCode: 404, message: 'Tabla no encontrada' };

    // || en PostgreSQL JSONB hace merge de objetos JSON:
    // { "a": 1, "b": 2 } || { "b": 3, "c": 4 } = { "a": 1, "b": 3, "c": 4 }
    // Así actualizamos solo los campos que cambiaron sin perder los demás.
    const result = await client.query<DynamicRow>(
      `UPDATE dynamic_rows
       SET data = data || $1::jsonb
       WHERE id = $2 AND table_id = $3 AND tenant_id = $4
       RETURNING id, tenant_id, table_id, data, created_at, updated_at`,
      [JSON.stringify(input.data), rowId, tableId, tenantId]
    );
    return result.rows[0] ?? null;
  } finally {
    client.release();
  }
}

// Eliminar una fila
export async function deleteRow(
  tenantId: string,
  tableId: string,
  rowId: string
): Promise<boolean> {
  const result = await query(
    `DELETE FROM dynamic_rows WHERE id = $1 AND table_id = $2 AND tenant_id = $3`,
    [rowId, tableId, tenantId]
  );
  return (result.rowCount ?? 0) > 0;
}

// ── HELPERS ───────────────────────────────────────────────────────

// Verifica que todas las columnas marcadas como required tengan valor en data
function validateRequiredColumns(
  columns: ColumnDefinition[],
  data: Record<string, unknown>
): void {
  const missing = columns
    .filter(col => col.required && (data[col.id] === undefined || data[col.id] === null || data[col.id] === ''))
    .map(col => col.name);

  if (missing.length > 0) {
    throw {
      statusCode: 400,
      message: `Campos requeridos faltantes: ${missing.join(', ')}`,
    };
  }
}
