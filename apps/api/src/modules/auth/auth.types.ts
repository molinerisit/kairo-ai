// Tipos que devuelve la API de auth en cada respuesta exitosa

export interface AuthUser {
  id: string;
  email: string;
  role: string;
  tenant_id: string;
}

export interface AuthResponse {
  access_token: string;
  // refresh_token: token opaco (UUID) de larga duración (7 días)
  // Se usa para obtener un nuevo access_token sin re-login
  refresh_token: string;
  token_type: 'Bearer';
  user: AuthUser;
}

// Payload que viaja dentro del JWT (JSON Web Token)
// Estos datos se pueden leer sin secret, pero no se pueden modificar
export interface JwtPayload {
  user_id: string;
  tenant_id: string;
  role: string;
  iat?: number;  // issued at (cuándo se emitió)
  exp?: number;  // expiration (cuándo vence)
}
