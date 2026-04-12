-- ================================================================
-- KAIRO AI — Schema inicial de la base de datos
-- ================================================================
-- Cómo usar este archivo:
--   1. Crear una base de datos PostgreSQL llamada "kairo_dev"
--   2. Ejecutar: psql -U postgres -d kairo_dev -f db/schema.sql
--
-- Convenciones:
--   - Todas las tablas usan UUID como PK (Primary Key)
--   - Todas las tablas de negocio tienen tenant_id (multi-tenancy)
--   - Los timestamps usan TIMESTAMPTZ (con zona horaria)
-- ================================================================

-- Extensión para generar UUIDs (Universally Unique Identifiers)
-- sin esto, gen_random_uuid() no funciona
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ────────────────────────────────────────────────────────────────
-- TENANTS — Negocios clientes de la plataforma
-- Cada negocio que se registra en Kairo AI es un tenant.
-- Es la tabla raíz de la que dependen todas las demás.
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tenants (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT        NOT NULL,
  -- slug: identificador amigable para URLs, ej: "peluqueria-marta"
  -- UNIQUE garantiza que no haya dos negocios con el mismo slug
  slug        TEXT        UNIQUE NOT NULL,
  industry    TEXT,
  -- plan determina qué funciones tiene habilitadas el negocio
  plan        TEXT        NOT NULL DEFAULT 'starter'
                          CHECK (plan IN ('starter', 'growth', 'executive')),
  status      TEXT        NOT NULL DEFAULT 'trial'
                          CHECK (status IN ('trial', 'active', 'suspended')),
  -- settings: configuración flexible en JSON, evita crear columnas
  -- para cada variante de configuración posible
  settings    JSONB       NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────────
-- USERS — Usuarios con acceso al panel de control
-- Un tenant puede tener múltiples usuarios con distintos roles.
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  -- tenant_id = NULL solo para superadmin (acceso a todo el sistema)
  tenant_id     UUID        REFERENCES tenants(id) ON DELETE CASCADE,
  email         TEXT        UNIQUE NOT NULL,
  -- NUNCA guardar password en texto plano. Siempre hash con bcrypt.
  password_hash TEXT        NOT NULL,
  role          TEXT        NOT NULL DEFAULT 'operator'
                            CHECK (role IN ('superadmin', 'owner', 'operator')),
  full_name     TEXT,
  is_active     BOOLEAN     NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice en tenant_id: acelera búsquedas del tipo
-- "dame todos los usuarios de este negocio"
CREATE INDEX IF NOT EXISTS idx_users_tenant_id ON users(tenant_id);

-- ────────────────────────────────────────────────────────────────
-- BUSINESS PROFILES — Configuración y conocimiento del negocio
-- Esta información la usan los agentes para responder correctamente.
-- Relación 1:1 con tenants (cada negocio tiene un solo perfil).
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS business_profiles (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  -- UNIQUE garantiza relación 1:1 con tenants
  tenant_id   UUID        UNIQUE NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  -- tone: cómo habla el negocio (ej: "informal y amigable", "formal")
  tone        TEXT,
  description TEXT,
  -- hours: horarios por día en JSON
  -- ej: {"lunes": "9:00-18:00", "sabado": "9:00-13:00", "domingo": "cerrado"}
  hours       JSONB       NOT NULL DEFAULT '{}',
  -- services: lista de servicios/productos con precio opcional
  -- ej: [{"name": "Corte", "price": 2500}, {"name": "Tinte"}]
  services    JSONB       NOT NULL DEFAULT '[]',
  -- faqs: preguntas frecuentes que el agente puede responder directo
  -- ej: [{"q": "¿Aceptan tarjeta?", "a": "Sí, débito y crédito"}]
  faqs        JSONB       NOT NULL DEFAULT '[]',
  whatsapp    TEXT,
  address     TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────────
-- Función que actualiza updated_at automáticamente en cada UPDATE
-- En lugar de hacerlo a mano en cada query, el trigger lo maneja
-- ────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar el trigger a cada tabla que tiene updated_at
CREATE TRIGGER tenants_updated_at
  BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER business_profiles_updated_at
  BEFORE UPDATE ON business_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
