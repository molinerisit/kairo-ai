import { randomUUID } from 'crypto';
import { query } from '../../shared/db/pool';
import { signToken } from '../../shared/lib/jwt';

// REFRESH_TOKEN_TTL: tiempo de vida del refresh token en días.
// 7 días es el estándar para apps B2B. Apps de consumo usan más (30-90 días).
const REFRESH_TOKEN_TTL_DAYS = 7;

// ── CREAR REFRESH TOKEN ───────────────────────────────────────────────────────
// Se llama después de un login o registro exitoso.
// Genera un UUID como token opaco y lo guarda en la DB con su vencimiento.

export async function createRefreshToken(
  userId: string,
  tenantId: string,
  meta: { userAgent?: string; ipAddress?: string } = {}
): Promise<string> {
  const token     = randomUUID();  // token opaco: no contiene datos, solo es una llave
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + REFRESH_TOKEN_TTL_DAYS);

  await query(
    `INSERT INTO refresh_tokens (user_id, tenant_id, token, expires_at, user_agent, ip_address)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [userId, tenantId, token, expiresAt, meta.userAgent ?? null, meta.ipAddress ?? null]
  );

  return token;
}

// ── ROTAR REFRESH TOKEN ───────────────────────────────────────────────────────
// "Rotación" significa: invalidar el refresh token usado y emitir uno nuevo.
// Esto limita el daño si alguien roba un token — solo puede usarse una vez.
// Si se detecta reuso de un token ya invalidado, es señal de robo (futuro: revocar todos).

export async function rotateRefreshToken(
  oldToken: string,
  meta: { userAgent?: string; ipAddress?: string } = {}
): Promise<{ accessToken: string; refreshToken: string } | null> {
  // 1. Buscar el token en la DB verificando que sea válido (no revocado, no vencido)
  const result = await query<{
    user_id:   string;
    tenant_id: string;
    role:      string;
  }>(
    `SELECT rt.user_id, rt.tenant_id, u.role
     FROM refresh_tokens rt
     JOIN users u ON u.id = rt.user_id
     WHERE rt.token = $1
       AND rt.revoked_at IS NULL
       AND rt.expires_at > now()`,
    [oldToken]
  );

  if (result.rows.length === 0) {
    // Token inválido, vencido o ya usado — rechazamos
    return null;
  }

  const { user_id, tenant_id, role } = result.rows[0];

  // 2. Revocar el token viejo (marcarlo como usado)
  await query(
    `UPDATE refresh_tokens SET revoked_at = now() WHERE token = $1`,
    [oldToken]
  );

  // 3. Emitir nuevos tokens
  const accessToken  = signToken({ user_id, tenant_id, role });
  const refreshToken = await createRefreshToken(user_id, tenant_id, meta);

  return { accessToken, refreshToken };
}

// ── REVOCAR TODOS LOS TOKENS DE UN USUARIO ───────────────────────────────────
// Se llama al hacer logout para invalidar todos los refresh tokens activos.
// Así aunque alguien tenga el token guardado, no podrá usarlo.

export async function revokeAllTokens(userId: string): Promise<void> {
  await query(
    `UPDATE refresh_tokens
     SET revoked_at = now()
     WHERE user_id = $1 AND revoked_at IS NULL`,
    [userId]
  );
}
