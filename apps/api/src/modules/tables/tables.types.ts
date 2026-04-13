// Tipos del módulo de tablas dinámicas

// Tipos de columna soportados
export type ColumnType =
  | 'text'
  | 'number'
  | 'date'
  | 'status'
  | 'phone'
  | 'money'
  | 'email'
  | 'url';

// Definición de una columna dentro de la tabla
export interface ColumnDefinition {
  id: string;             // UUID generado al crear la columna
  name: string;           // nombre visible (ej: "Nombre del cliente")
  type: ColumnType;       // tipo de dato
  required: boolean;      // si es obligatorio al crear una fila
  options?: string[];     // opciones posibles (solo para tipo "status")
}

// Una tabla dinámica
export interface DynamicTable {
  id: string;
  tenant_id: string;
  name: string;
  table_type: 'clients' | 'appointments' | 'leads' | 'custom';
  columns: ColumnDefinition[];
  created_at: string;
}

// Una fila de la tabla
export interface DynamicRow {
  id: string;
  tenant_id: string;
  table_id: string;
  data: Record<string, unknown>; // { "col_uuid": valor }
  created_at: string;
  updated_at: string;
}
