import bcrypt from 'bcryptjs';
import { pool } from '../../shared/db/pool';
import { signToken } from '../../shared/lib/jwt';
import { createRefreshToken } from './auth.refresh.service';
import type { RegisterInput } from './auth.schema';
import type { AuthResponse } from './auth.types';

// toSlug: convierte el nombre del negocio en un slug amigable para URLs.
// "Peluquería Marta & Co." → "peluqueria-marta-co"
function toSlug(name: string): string {
  return name
    .toLowerCase()
    .normalize('NFD')                        // descompone caracteres acentuados
    .replace(/[\u0300-\u036f]/g, '')         // elimina los acentos
    .replace(/[^a-z0-9\s]/g, '')            // elimina caracteres especiales
    .trim()
    .replace(/\s+/g, '-');                   // espacios → guiones
}

// uniqueSlug: genera un slug único verificando contra la DB.
// Si "peluqueria-marta" ya existe, prueba "peluqueria-marta-2", "-3", etc.
// Usa el client de la transacción para que la verificación sea atómica.
async function uniqueSlug(
  client: { query: (text: string, params: unknown[]) => Promise<{ rows: unknown[] }> },
  base: string
): Promise<string> {
  let candidate = base;
  let counter   = 1;

  while (true) {
    const { rows } = await client.query(
      'SELECT 1 FROM tenants WHERE slug = $1',
      [candidate]
    );
    if (rows.length === 0) return candidate;   // libre → lo usamos
    counter++;
    candidate = `${base}-${counter}`;
  }
}

// SALT_ROUNDS: cuántas veces bcrypt procesa el password.
// 12 es el balance recomendado entre seguridad y velocidad.
// Más alto = más seguro pero más lento (12 tarda ~250ms, que está bien).
const SALT_ROUNDS = 12;

export async function register(input: RegisterInput): Promise<AuthResponse> {
  // Obtenemos un cliente del pool para poder usar transacciones.
  // Con pool.query() no podemos usar BEGIN/COMMIT porque cada query
  // podría ir a una conexión distinta del pool.
  const client = await pool.connect();

  try {
    // Verificar si el email ya existe ANTES de abrir la transacción.
    // Es una lectura simple que no necesita transacción.
    const existing = await client.query(
      'SELECT id FROM users WHERE email = $1',
      [input.email]
    );

    if (existing.rows.length > 0) {
      // Usamos un objeto con statusCode para que el controller
      // sepa exactamente qué código HTTP devolver
      throw { statusCode: 409, message: 'El email ya está registrado' };
    }

    // ── TRANSACCIÓN ────────────────────────────────────────────────
    // Una transacción garantiza que si algo falla en el medio,
    // NADA se guarda. O se crean tenant + perfil + usuario juntos,
    // o no se crea ninguno. Esto es ATOMICIDAD.
    await client.query('BEGIN');

    // 1. Crear el tenant (el negocio)
    const slug = await uniqueSlug(client, toSlug(input.business_name));
    const tenantResult = await client.query<{ id: string }>(
      `INSERT INTO tenants (name, slug)
       VALUES ($1, $2)
       RETURNING id`,
      [input.business_name, slug]
    );
    const tenantId = tenantResult.rows[0].id;

    // 2. Crear el perfil vacío del negocio (se completa en onboarding)
    await client.query(
      `INSERT INTO business_profiles (tenant_id) VALUES ($1)`,
      [tenantId]
    );

    // 3. Hashear el password y crear el usuario owner
    // NUNCA se guarda el password en texto plano. bcrypt.hash devuelve
    // un hash diferente cada vez gracias al salt aleatorio incorporado.
    const passwordHash = await bcrypt.hash(input.password, SALT_ROUNDS);

    const userResult = await client.query<{ id: string; email: string; role: string }>(
      `INSERT INTO users (tenant_id, email, password_hash, role)
       VALUES ($1, $2, $3, 'owner')
       RETURNING id, email, role`,
      [tenantId, input.email, passwordHash]
    );
    const user = userResult.rows[0];

    await client.query('COMMIT');
    // ── FIN TRANSACCIÓN ────────────────────────────────────────────

    // Generar JWT con los datos necesarios para identificar
    // al usuario y su negocio en cada request futuro
    const access_token = signToken({
      user_id: user.id,
      tenant_id: tenantId,
      role: user.role,
    });

    // Generar refresh token (UUID opaco, guardado en DB, dura 7 días)
    const refresh_token = await createRefreshToken(user.id, tenantId);

    return {
      access_token,
      refresh_token,
      token_type: 'Bearer',
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        tenant_id: tenantId,
      },
    };
  } catch (err) {
    // Si algo falló después del BEGIN, revertimos todo
    await client.query('ROLLBACK').catch(() => null);
    throw err;
  } finally {
    // SIEMPRE devolver el cliente al pool, pase lo que pase.
    // Si no lo hacemos, el pool se agota y el servidor deja de responder.
    client.release();
  }
}
