# Modelo de Datos — Kairo AI

## Principio de multi-tenancy

Cada tabla de negocio tiene `tenant_id`. El tenant es el negocio cliente (ej: "Peluquería Marta"). Un tenant puede tener múltiples usuarios con distintos roles.

---

## Tablas principales (Sprint 1 y 2)

### `tenants` — Negocios clientes

```sql
CREATE TABLE tenants (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,                    -- nombre del negocio
  slug        TEXT UNIQUE NOT NULL,             -- identificador en URL (ej: peluqueria-marta)
  industry    TEXT,                             -- rubro (peluquería, consultorio, etc.)
  plan        TEXT DEFAULT 'starter',           -- starter | growth | executive
  status      TEXT DEFAULT 'active',            -- active | suspended | trial
  settings    JSONB DEFAULT '{}',               -- configuración flexible del negocio
  created_at  TIMESTAMPTZ DEFAULT now()
);
```

### `users` — Usuarios del sistema

```sql
CREATE TABLE users (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    UUID REFERENCES tenants(id) ON DELETE CASCADE,
  email        TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role         TEXT NOT NULL DEFAULT 'operator',  -- superadmin | owner | operator
  full_name    TEXT,
  is_active    BOOLEAN DEFAULT true,
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- Índice (acceso rápido) para búsqueda por tenant
CREATE INDEX idx_users_tenant ON users(tenant_id);
```

### `business_profiles` — Configuración del negocio

```sql
CREATE TABLE business_profiles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID UNIQUE REFERENCES tenants(id) ON DELETE CASCADE,
  tone        TEXT,                          -- cómo habla el negocio
  description TEXT,                          -- descripción del negocio
  hours       JSONB DEFAULT '{}',            -- horarios por día
  services    JSONB DEFAULT '[]',            -- servicios/productos
  faqs        JSONB DEFAULT '[]',            -- preguntas frecuentes
  whatsapp    TEXT,                          -- número de WhatsApp
  updated_at  TIMESTAMPTZ DEFAULT now()
);
```

### `conversations` — Conversaciones por cliente del negocio

```sql
CREATE TABLE conversations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID REFERENCES tenants(id) ON DELETE CASCADE,
  contact_name  TEXT,
  contact_phone TEXT NOT NULL,
  channel       TEXT DEFAULT 'whatsapp',       -- whatsapp | web
  status        TEXT DEFAULT 'new',            -- new | in_progress | resolved | escalated
  priority      TEXT DEFAULT 'green',          -- green | yellow | red
  assigned_agent TEXT,                         -- secretario | vendedor | soporte
  last_message_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_conversations_tenant ON conversations(tenant_id);
CREATE INDEX idx_conversations_status ON conversations(tenant_id, status);
```

### `messages` — Mensajes dentro de una conversación

```sql
CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID REFERENCES tenants(id) ON DELETE CASCADE,
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  role            TEXT NOT NULL,               -- user | assistant | system
  content         TEXT NOT NULL,
  metadata        JSONB DEFAULT '{}',          -- tokens usados, modelo, costo, etc.
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
```

### `dynamic_tables` — Definición de tablas dinámicas tipo Excel

```sql
CREATE TABLE dynamic_tables (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID REFERENCES tenants(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,                   -- ej: "Clientes", "Turnos", "Leads"
  table_type  TEXT DEFAULT 'custom',           -- clients | appointments | leads | custom
  columns     JSONB NOT NULL DEFAULT '[]',     -- definición de columnas
  created_at  TIMESTAMPTZ DEFAULT now()
);
```

Estructura de `columns` (JSONB):
```json
[
  { "id": "uuid", "name": "Nombre", "type": "text", "required": true },
  { "id": "uuid", "name": "Teléfono", "type": "phone", "required": true },
  { "id": "uuid", "name": "Estado", "type": "status", "options": ["Nuevo", "En proceso", "Cerrado"] },
  { "id": "uuid", "name": "Próxima cita", "type": "date" },
  { "id": "uuid", "name": "Valor", "type": "money" }
]
```

### `dynamic_rows` — Filas de las tablas dinámicas

```sql
CREATE TABLE dynamic_rows (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  UUID REFERENCES tenants(id) ON DELETE CASCADE,
  table_id   UUID REFERENCES dynamic_tables(id) ON DELETE CASCADE,
  data       JSONB NOT NULL DEFAULT '{}',      -- { "col_uuid": "valor", ... }
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_rows_table ON dynamic_rows(table_id);
```

### `calendar_events` — Eventos del calendario (Sprint 2)

```sql
CREATE TABLE calendar_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID REFERENCES tenants(id) ON DELETE CASCADE,
  row_id      UUID REFERENCES dynamic_rows(id),  -- fila asociada en tabla (opcional)
  title       TEXT NOT NULL,
  description TEXT,
  start_at    TIMESTAMPTZ NOT NULL,
  end_at      TIMESTAMPTZ NOT NULL,
  status      TEXT DEFAULT 'confirmed',           -- confirmed | pending | cancelled | no_show
  contact_phone TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_events_tenant_date ON calendar_events(tenant_id, start_at);
```

### `ai_logs` — Registro de uso de IA

```sql
CREATE TABLE ai_logs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    UUID REFERENCES tenants(id) ON DELETE CASCADE,
  conversation_id UUID REFERENCES conversations(id),
  action       TEXT NOT NULL,                  -- classify | extract | generate | summarize
  model        TEXT NOT NULL,                  -- nombre del modelo usado
  input_tokens INT,
  output_tokens INT,
  cost_usd     DECIMAL(10,6),
  created_at   TIMESTAMPTZ DEFAULT now()
);
```

---

## Relaciones clave

```
tenants
  ├── users (1:N)
  ├── business_profiles (1:1)
  ├── conversations (1:N)
  │     └── messages (1:N)
  ├── dynamic_tables (1:N)
  │     └── dynamic_rows (1:N)
  ├── calendar_events (1:N)
  └── ai_logs (1:N)
```

---

## Por qué JSONB para columnas y settings

PostgreSQL JSONB permite guardar estructuras flexibles con búsqueda eficiente. Se usa para:
- Definición de columnas dinámicas (cada negocio tiene columnas distintas)
- Settings del negocio (configuración variable por tenant)
- Metadata de mensajes (tokens, costo, modelo, versión del prompt)
- Horarios y servicios (estructuras que varían por negocio)

Esto evita crear tablas separadas para cada variante de configuración.
