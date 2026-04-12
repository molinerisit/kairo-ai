import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

// Pool: grupo de conexiones reutilizables a la base de datos.
// En lugar de abrir y cerrar una conexión por cada query,
// el pool mantiene conexiones abiertas y las reutiliza.
// Esto mejora la performance significativamente.
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // max: máximo de conexiones simultáneas al pool
  max: 20,
  // idleTimeoutMillis: tiempo antes de cerrar una conexión inactiva
  idleTimeoutMillis: 30000,
  // connectionTimeoutMillis: tiempo máximo para obtener una conexión del pool
  connectionTimeoutMillis: 2000,
});

// Verificar conexión al iniciar el servidor
pool.on('connect', () => {
  console.log('[DB] Nueva conexión establecida');
});

pool.on('error', (err) => {
  console.error('[DB] Error inesperado en cliente idle:', err);
  process.exit(-1);
});

// query: wrapper que expone el pool de forma limpia al resto de la app.
// Usar esto en lugar de importar pool directamente en cada módulo.
export const query = (text: string, params?: unknown[]) =>
  pool.query(text, params);
