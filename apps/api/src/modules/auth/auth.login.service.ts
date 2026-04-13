import bcrypt from 'bcryptjs';
import { query } from '../../shared/db/pool';
import { signToken } from '../../shared/lib/jwt';
import { createRefreshToken } from './auth.refresh.service';
import type { LoginInput } from './auth.schema';
import type { AuthResponse } from './auth.types';

export async function login(input: LoginInput): Promise<AuthResponse> {
  // Buscar el usuario por email. Traemos el hash para comparar.
  // NUNCA traer el password_hash en endpoints que no lo necesitan.
  const result = await query<{
    id: string;
    email: string;
    role: string;
    tenant_id: string;
    password_hash: string;
    is_active: boolean;
  }>(
    `SELECT id, email, role, tenant_id, password_hash, is_active
     FROM users
     WHERE email = $1`,
    [input.email]
  );

  const user = result.rows[0];

  // Usamos el MISMO mensaje de error para "usuario no existe"
  // y para "password incorrecto".
  // Si diferenciamos los mensajes, un atacante puede enumerar
  // qué emails están registrados en el sistema.
  const INVALID_CREDENTIALS = 'Credenciales inválidas';

  if (!user) {
    throw { statusCode: 401, message: INVALID_CREDENTIALS };
  }

  if (!user.is_active) {
    throw { statusCode: 401, message: 'Cuenta desactivada' };
  }

  // bcrypt.compare compara el password en texto plano con el hash.
  // Internamente extrae el salt del hash y aplica el mismo proceso.
  // Devuelve true si coinciden, false si no.
  const passwordMatch = await bcrypt.compare(input.password, user.password_hash);

  if (!passwordMatch) {
    throw { statusCode: 401, message: INVALID_CREDENTIALS };
  }

  const access_token  = signToken({
    user_id: user.id,
    tenant_id: user.tenant_id,
    role: user.role,
  });

  const refresh_token = await createRefreshToken(user.id, user.tenant_id);

  return {
    access_token,
    refresh_token,
    token_type: 'Bearer',
    user: {
      id: user.id,
      email: user.email,
      role: user.role,
      tenant_id: user.tenant_id,
    },
  };
}
