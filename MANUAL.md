# Manual de Trabajo Profesional — Kairo AI

> Este documento es una guía de referencia personal. Explica cómo se trabajó este proyecto desde cero, qué decisiones se tomaron y por qué. Útil para retomar trabajo después de días sin tocar el proyecto, para entrevistas técnicas y como plantilla para futuros proyectos.

---

## Índice

1. [Qué es Kairo AI](#1-qué-es-kairo-ai)
2. [Cómo se inicia un proyecto profesionalmente](#2-cómo-se-inicia-un-proyecto-profesionalmente)
3. [Documentos que se crean antes de escribir código](#3-documentos-que-se-crean-antes-de-escribir-código)
4. [Arquitectura del sistema](#4-arquitectura-del-sistema)
5. [Stack tecnológico y por qué](#5-stack-tecnológico-y-por-qué)
6. [Modelo de datos](#6-modelo-de-datos)
7. [Flujo de trabajo diario con Git](#7-flujo-de-trabajo-diario-con-git)
8. [Gestión de tareas con GitHub Issues y Projects](#8-gestión-de-tareas-con-github-issues-y-projects)
9. [Sprints y planificación](#9-sprints-y-planificación)
10. [Convenciones del proyecto](#10-convenciones-del-proyecto)
11. [Glosario de términos técnicos](#11-glosario-de-términos-técnicos)
12. [Preguntas frecuentes de entrevista](#12-preguntas-frecuentes-de-entrevista)
13. [Sprint 1 — Log de decisiones técnicas](#13-sprint-1--log-de-decisiones-técnicas)

---

## 1. Qué es Kairo AI

Kairo AI es un SaaS (Software as a Service — software por suscripción en la nube) de asistentes digitales para negocios pequeños y medianos. El problema que resuelve: los negocios pierden ventas, clientes y tiempo porque operan por WhatsApp de forma manual y desorganizada.

**Los tres agentes del sistema:**
- **Secretario** — gestiona citas, agenda, confirmaciones y recordatorios
- **Vendedor** — responde consultas, hace seguimiento y recupera ventas perdidas
- **Soporte** — resuelve dudas frecuentes, detecta enojo y escala casos complejos

**Canal principal:** WhatsApp Business API

**Panel de control:** web app donde el dueño ve tabla de datos, calendario y conversaciones

---

## 2. Cómo se inicia un proyecto profesionalmente

En una empresa real, antes de escribir una sola línea de código se producen estos documentos en este orden:

```
1. PRD (Product Requirements Document — Documento de Requisitos del Producto)
      ↓
2. Arquitectura técnica
      ↓
3. Modelo de datos
      ↓
4. Workflow de desarrollo (Git flow, convenciones, CI/CD)
      ↓
5. Backlog en herramienta de gestión (GitHub Projects, Linear, Jira)
      ↓
6. Sprint 1 definido con issues concretos
      ↓
7. Setup del repositorio
      ↓
8. Primera línea de código
```

**Por qué este orden:** cada documento elimina ambigüedad para el siguiente. Si empezás a codear sin modelo de datos definido, vas a cambiar la base de datos tres veces. Si empezás sin arquitectura, vas a mezclar responsabilidades entre módulos.

---

## 3. Documentos que se crean antes de escribir código

### PRD (Product Requirements Document — Documento de Requisitos del Producto)
Define qué se está construyendo, para quién, por qué y qué queda fuera del MVP (Minimum Viable Product — Producto Mínimo Viable). Incluye casos de uso, épicas e historias de usuario.

**En este proyecto:** el PRD de Kairo AI vive en el product brief que generamos antes de empezar a codear.

### Arquitectura técnica
Explica cómo están organizadas las capas del sistema, cómo se comunican, qué responsabilidad tiene cada módulo. Vive en `docs/architecture.md`.

### Modelo de datos
Define las tablas de la base de datos, sus columnas, tipos, relaciones e índices. Es la fuente de verdad para el backend. Vive en `docs/data-model.md`.

### Workflow de desarrollo
Define cómo trabaja el equipo: convenciones de Git, cómo se nombran los branches, cómo se escriben los commits, cómo se abre un PR. Vive en `docs/workflow.md`.

---

## 4. Arquitectura del sistema

### Principio de separación por capas

```
Canal (WhatsApp / Web)
      ↓
API (Node.js) — Orquestador central
      ↓
Módulos de negocio (auth, tenants, conversations, tables, agents...)
      ↓
Capa de datos (PostgreSQL + Redis)
      ↓
Capa de IA (modelos externos)
      ↓
Capa de auditoría (logs de todo)
```

### Por qué separación modular en el backend

En lugar de organizar por tipo técnico (`controllers/`, `models/`, `services/`) se organiza por dominio de negocio:

```
modules/
  auth/           ← todo lo relacionado a autenticación
  tenants/        ← todo lo relacionado a negocios
  conversations/  ← todo lo relacionado a mensajes
  tables/         ← todo lo relacionado a tablas dinámicas
```

**Ventaja:** cuando hay que cambiar la lógica de conversaciones, todos los archivos relevantes están en un solo lugar. Escala mejor en equipos grandes.

### Multi-tenancy (aislamiento de datos entre clientes)

Cada registro en la base de datos tiene un `tenant_id`. El middleware (código que se ejecuta antes de cada request) extrae el `tenant_id` del JWT (JSON Web Token — credencial cifrada de sesión) y lo agrega automáticamente a todas las consultas. Un negocio nunca puede ver datos de otro.

---

## 5. Stack tecnológico y por qué

### Frontend: Flutter Web

**Por qué Flutter Web y no React/Next.js:**
- El panel de control tiene componentes complejos: tabla tipo Excel editable, calendario drag & drop, bandeja de conversaciones en tiempo real.
- Flutter tiene mejor performance en UIs complejas y ricas.
- El mismo código puede compilar a iOS/Android en el futuro sin reescribir.
- Contexto del developer: ya tiene experiencia con Flutter.

**Cuándo no usarías Flutter Web:** si necesitás SEO (Search Engine Optimization — posicionamiento en buscadores) intensivo, porque Flutter Web no es favorable para indexación. Para una app autenticada (panel de control), eso no importa.

### Backend: Node.js

**Por qué Node.js:**
- Ecosistema enorme, ideal para integraciones con APIs externas (WhatsApp, proveedores de IA, servicios de email)
- Manejo eficiente de I/O asíncrono (operaciones de entrada/salida) — importante cuando el sistema espera respuestas de WhatsApp e IA constantemente
- JavaScript en ambos lados facilita compartir tipos y lógica en proyectos fullstack

### Base de datos: PostgreSQL + JSONB

**Por qué PostgreSQL y no MongoDB:**
- Los datos de negocio tienen relaciones claras (tenants → users → conversations → messages). Una base de datos relacional es la herramienta correcta.
- JSONB (JSON Binario — formato de datos flexible dentro de PostgreSQL) permite manejar la parte dinámica (columnas configurables por negocio) sin sacrificar las ventajas relacionales.

**Cuándo se usa JSONB:** para datos cuya estructura varía por tenant: configuración del negocio, definición de columnas de tablas dinámicas, metadata de mensajes.

### Cache y jobs: Redis

- **Cache:** respuestas frecuentes que no cambian (configuración del negocio, FAQs) se guardan en memoria para no consultar la base de datos en cada request.
- **Queue (cola de trabajo):** tareas que no deben bloquear una respuesta HTTP (recordatorios, seguimientos automáticos, resúmenes diarios) se encolan y se procesan en background.

---

## 6. Modelo de datos

### Tablas clave del Sprint 1 y 2

| Tabla | Propósito |
|---|---|
| `tenants` | Cada negocio cliente de la plataforma |
| `users` | Usuarios con acceso al panel |
| `business_profiles` | Configuración del negocio (tono, horarios, servicios) |
| `conversations` | Hilo de mensajes con un contacto |
| `messages` | Mensajes individuales dentro de una conversación |
| `dynamic_tables` | Definición de tablas tipo Excel del negocio |
| `dynamic_rows` | Filas de esas tablas |
| `calendar_events` | Citas y eventos del calendario |
| `ai_logs` | Registro de cada llamada a IA con costo y tokens |

### Decisión: UUID como PK (Primary Key — clave primaria)

Se usan UUID (Universally Unique Identifier — identificador único universal) en vez de IDs numéricos secuenciales. **Por qué:** en un sistema multi-tenant, los IDs numéricos como `id=1` pueden filtrarse por enumeración. Un UUID como `a3f2b1c4-...` es imposible de adivinar.

### Índices

Un índice (index) es una estructura que acelera las búsquedas. Se crea en columnas que se filtran frecuentemente:
```sql
CREATE INDEX idx_conversations_tenant ON conversations(tenant_id);
```
Sin este índice, buscar todas las conversaciones de un tenant requeriría leer toda la tabla.

---

## 7. Flujo de trabajo diario con Git

### El ciclo completo

```bash
# 1. Actualizar main
git checkout main && git pull origin main

# 2. Crear branch para la tarea
git checkout -b feature/KAI-05-tabla-edicion-inline

# 3. Desarrollar... guardar cambios frecuentemente
git add src/modules/tables/
git commit -m "feat(tables): add inline row editing with optimistic update"

# 4. Push y abrir PR
git push origin feature/KAI-05-tabla-edicion-inline
# → Abrir PR en GitHub contra main

# 5. Hacer merge en GitHub → el branch se cierra
```

### Mensajes de commit semánticos

Formato: `tipo(módulo): descripción en inglés en infinitivo`

```
feat(auth): add JWT refresh token endpoint
fix(tables): prevent empty row save on blur
chore(docker): add postgres and redis services
refactor(agents): extract classification to shared service
```

**Por qué en inglés:** convención universal en la industria. El código y los commits son en inglés, los documentos internos pueden ser en español.

**Por qué mensajes descriptivos:** `git log` es la historia del proyecto. En 6 meses, "fix bug" no te dice nada. "fix(tables): prevent crash when deleting last row" sí.

---

## 8. Gestión de tareas con GitHub Issues y Projects

### Por qué GitHub Issues y no Jira

- Jira es poderoso pero pesado. Tiene sentido para equipos de 20+ personas con procesos complejos.
- GitHub Issues es donde vive el código — issue → branch → PR → merge queda todo trazado en un solo lugar.
- Es lo que usa la mayoría de startups modernas y proyectos open source.
- Linear es una alternativa más moderna si el equipo crece.

### Anatomía de un issue bien escrito

```
Título: [AUTH] Crear endpoint de registro con validación de email

Descripción:
Necesitamos un endpoint POST /api/auth/register que:
- Reciba email, password y tenant_name
- Valide que el email no esté en uso
- Cree el tenant y el usuario owner en una sola transacción
- Devuelva JWT firmado

Criterios de aceptación (Definition of Done):
- [ ] POST /api/auth/register devuelve 201 con JWT si los datos son válidos
- [ ] Si el email ya existe, devuelve 409 con mensaje claro
- [ ] El password se guarda hasheado (nunca en texto plano)
- [ ] Se crea un tenant y un usuario en la misma transacción de base de datos

Labels: feature, sprint-1
```

### GitHub Projects como tablero Kanban

Kanban es un sistema de tarjetas visuales con columnas:
```
Backlog | Sprint actual | In Progress | In Review | Done
```

Cada issue es una tarjeta. Al empezar a trabajar, se mueve a "In Progress". Al abrir el PR, a "In Review". Al mergear, a "Done".

---

## 9. Sprints y planificación

### Qué es un Sprint

Un sprint es un período de trabajo de duración fija (generalmente 1-2 semanas) con un objetivo claro. Al final del sprint, debe haber algo funcionando que se pueda mostrar.

### Sprint 1 — Objetivo: base funcional del sistema

| # | Issue | Descripción |
|---|---|---|
| KAI-01 | Estructura del repo y setup inicial | Carpetas, .gitignore, README |
| KAI-02 | Configurar PostgreSQL y schema base | Tablas: tenants, users |
| KAI-03 | Endpoint registro (POST /auth/register) | Crea tenant + owner, devuelve JWT |
| KAI-04 | Endpoint login (POST /auth/login) | Verifica credenciales, devuelve JWT |
| KAI-05 | Middleware de autenticación y tenant | Valida JWT en cada request protegido |
| KAI-06 | Dashboard base en Flutter (vacío) | Layout con sidebar y rutas básicas |
| KAI-07 | Tabla dinámica — estructura base | CRUD de definición de columnas |
| KAI-08 | Tabla dinámica — UI editable | Vista tipo Excel con edición inline |

### Definition of Done (Definición de Terminado)

Una tarea está "terminada" cuando:
1. El código funciona según los criterios de aceptación
2. El PR fue revisado (aunque sea por uno mismo)
3. Fue mergeado a main
4. No rompió nada que funcionaba antes (regression)

---

## 10. Convenciones del proyecto

### Estructura de carpetas del backend

```
modules/{nombre}/
  {nombre}.routes.ts      ← Define los endpoints HTTP
  {nombre}.controller.ts  ← Recibe el request, llama al service
  {nombre}.service.ts     ← Lógica de negocio
  {nombre}.schema.ts      ← Validación de datos de entrada (Zod)
  {nombre}.types.ts       ← Tipos TypeScript del módulo
```

### Nomenclatura

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos | kebab-case | `auth.service.ts` |
| Clases | PascalCase | `AuthService` |
| Funciones/variables | camelCase | `getTenantById` |
| Constantes | UPPER_SNAKE_CASE | `MAX_RETRIES` |
| Tablas de BD | snake_case | `dynamic_rows` |
| Branches | kebab-case | `feature/KAI-03-auth-login` |

### Variables de entorno

```bash
# .env.example (se commitea sin valores reales)
DATABASE_URL=postgresql://user:pass@localhost:5432/kairo
REDIS_URL=redis://localhost:6379
JWT_SECRET=change_this_in_production
WHATSAPP_TOKEN=
AI_API_KEY=
```

---

## 11. Glosario de términos técnicos

| Término | Significado |
|---|---|
| **SaaS** | Software as a Service — software por suscripción mensual, sin instalación |
| **MVP** | Minimum Viable Product — versión mínima del producto que valida la idea |
| **PRD** | Product Requirements Document — documento que define qué se construye y por qué |
| **API** | Application Programming Interface — interfaz que permite que dos sistemas se comuniquen |
| **REST** | Representational State Transfer — estilo de arquitectura para APIs usando HTTP |
| **JWT** | JSON Web Token — credencial cifrada que prueba que el usuario está autenticado |
| **CRUD** | Create Read Update Delete — las cuatro operaciones básicas de datos |
| **CI/CD** | Continuous Integration / Continuous Deployment — pipeline que corre tests y deploya automáticamente |
| **PR** | Pull Request — solicitud para fusionar código de un branch a otro |
| **Multi-tenant** | Un sistema compartido donde cada cliente tiene sus datos completamente aislados |
| **Middleware** | Código que se ejecuta entre el request y el handler principal (ej: verificar autenticación) |
| **ORM** | Object-Relational Mapper — librería que convierte objetos de código en queries de base de datos |
| **JSONB** | JSON Binario en PostgreSQL — permite guardar datos flexibles con búsqueda eficiente |
| **UUID** | Universally Unique Identifier — identificador único de 128 bits, imposible de adivinar |
| **PK** | Primary Key — columna que identifica únicamente cada fila en una tabla |
| **FK** | Foreign Key — columna que referencia la PK de otra tabla |
| **Index** | Índice — estructura que acelera búsquedas en columnas frecuentemente consultadas |
| **Queue** | Cola de trabajo — lista de tareas que se procesan en background, sin bloquear requests |
| **Cache** | Almacenamiento temporal en memoria para evitar recalcular o consultar datos frecuentes |
| **Hash** | Resultado de una función criptográfica unidireccional (usado para guardar passwords) |
| **Endpoint** | URL específica de la API que realiza una acción determinada |
| **Payload** | Datos que viajan dentro de una request o response HTTP |
| **Schema** | Definición de la estructura de datos: tablas, columnas, tipos y restricciones |
| **Migration** | Script que modifica la estructura de la base de datos de forma controlada y reversible |
| **Monorepo** | Un repositorio que contiene múltiples proyectos (ej: frontend + backend juntos) |
| **Scaffold** | Estructura base de un proyecto generada automáticamente |
| **Lint** | Análisis estático de código que detecta errores de estilo o problemas potenciales |
| **Staging** | Entorno de prueba pre-producción, idéntico a producción pero sin usuarios reales |
| **Rate limiting** | Límite de requests por tiempo para proteger la API de abuso |
| **Rollback** | Revertir un deploy o migración al estado anterior |
| **Kanban** | Sistema visual de gestión de tareas con columnas (Pendiente / En progreso / Hecho) |
| **Sprint** | Período de trabajo de duración fija (1-2 semanas) con objetivo claro |
| **Backlog** | Lista priorizada de todas las tareas pendientes del proyecto |
| **GTM** | Go-To-Market — estrategia para lanzar y conseguir los primeros clientes |
| **UX** | User Experience — experiencia del usuario al interactuar con el producto |
| **SEO** | Search Engine Optimization — optimización para aparecer en buscadores |
| **WebSocket** | Protocolo de comunicación bidireccional en tiempo real entre cliente y servidor |
| **ACID** | Atomicity Consistency Isolation Durability — propiedades de transacciones en bases de datos |
| **Transaction** | Operación de base de datos que se ejecuta completa o no se ejecuta (todo o nada) |

---

## 12. Preguntas frecuentes de entrevista

### "¿Cómo manejás multi-tenancy?"

> "Cada tabla tiene un `tenant_id`. El JWT incluye el `tenant_id` del usuario autenticado. Un middleware extrae ese valor y lo agrega automáticamente a todas las queries. Es imposible que un tenant consulte datos de otro. Usé este patrón porque es simple, eficiente y no requiere bases de datos separadas por cliente, lo que haría el costo operativo inmanejable."

### "¿Por qué PostgreSQL y no MongoDB?"

> "El dominio tiene relaciones claras: tenants, usuarios, conversaciones, mensajes, eventos. Una base relacional es la herramienta correcta. Para la parte flexible (configuración por negocio, columnas dinámicas) usé JSONB de PostgreSQL, que da lo mejor de los dos mundos: estructura relacional donde se necesita, flexibilidad donde se necesita."

### "¿Cómo controlás los costos de IA?"

> "La IA interviene solo cuando agrega valor real. Tareas repetitivas se resuelven con reglas y templates. Para clasificación y extracción uso modelos económicos. Para respuestas visibles al cliente uso un modelo de calidad media. Todo pasa por una capa centralizada que registra tokens y costo en `ai_logs`. Con eso puedo calcular el margen real por cliente."

### "¿Qué es un PR y cómo trabajás con Git?"

> "Un Pull Request es una solicitud para fusionar código de un branch de feature a main. El flujo es: creo un issue, abro un branch desde main, desarrollo, hago commits con mensajes semánticos, abro el PR describiendo qué hace y cómo probarlo, reviso antes de mergear. Nunca commiteo directo a main. Así el historial es limpio y cada cambio está trazado a un issue."

### "¿Cómo organizás el código en el backend?"

> "Por módulos de dominio, no por capas técnicas. Cada módulo tiene sus routes, controller, service, schema de validación y tipos. Routes recibe la request y enruta, controller valida y coordina, service tiene la lógica de negocio pura. Esta separación hace que sea fácil encontrar qué toca cada cosa y que los módulos sean independientes entre sí."

### "¿Cómo funciona la autenticación?"

> "El usuario envía email y password. El backend verifica contra la base de datos (el password nunca se guarda en texto plano, siempre hasheado con bcrypt). Si es válido, genera un JWT firmado que incluye user_id, tenant_id y role. El token viaja en el header Authorization de cada request. El middleware lo verifica y extrae el contexto del usuario antes de llegar al handler."

### "¿Qué es un índice en base de datos y cuándo lo usás?"

> "Un índice es una estructura que acelera búsquedas en columnas frecuentemente filtradas. Sin índice, una query hace un full table scan (lee toda la tabla). Lo creo en columnas que aparecen en WHERE frecuentemente. Por ejemplo, `tenant_id` en todas las tablas de negocio, porque casi toda query filtra por tenant. El trade-off es que los índices usan espacio en disco y ralentizan ligeramente los writes."

---

## 13. Sprint 1 — Log de decisiones técnicas

> Esta sección documenta cada decisión tomada durante el Sprint 1, en orden cronológico. Sirve para entender el "por qué" detrás de cada elección.

---

### Issue #1 — Schema inicial de PostgreSQL

**Branch:** `chore/KAI-01-db-schema`

#### Setup del proyecto Node.js

**Comando usado:**
```bash
cd apps/api
npm init -y
npm install express pg dotenv zod bcryptjs jsonwebtoken cors helmet
npm install -D typescript tsx nodemon @types/express @types/pg @types/bcryptjs @types/jsonwebtoken @types/cors @types/node eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser
```

**Por qué cada dependencia:**

| Paquete | Para qué sirve |
|---|---|
| `express` | Framework web para crear los endpoints de la API |
| `pg` | Cliente de PostgreSQL para Node.js (pool de conexiones) |
| `dotenv` | Carga variables de entorno desde el archivo `.env` |
| `zod` | Validación de schemas — valida variables de entorno y datos de entrada |
| `bcryptjs` | Hash de passwords. Nunca se guarda el password en texto plano |
| `jsonwebtoken` | Generación y verificación de JWT (tokens de autenticación) |
| `cors` | Permite que el frontend llame a la API desde otro dominio/puerto |
| `helmet` | Agrega headers HTTP de seguridad automáticamente |
| `typescript` | Tipado estático — detecta errores antes de correr el código |
| `tsx` | Ejecuta TypeScript directamente en desarrollo, sin compilar |
| `nodemon` | Reinicia el servidor automáticamente al guardar un archivo |

**tsconfig.json — opciones clave:**
- `"strict": true` — activa todas las verificaciones de tipos estrictas. Encuentra más bugs en tiempo de compilación.
- `"target": "ES2022"` — compila a JavaScript moderno. Node.js 20 lo soporta.
- `"esModuleInterop": true` — permite importar módulos CommonJS con `import x from 'x'` en lugar de `require`.

---

#### Estructura de carpetas del backend

```
apps/api/
├── db/
│   └── schema.sql        ← Schema de la base de datos
├── src/
│   ├── config/
│   │   └── env.ts        ← Validación de variables de entorno con Zod
│   ├── shared/
│   │   └── db/
│   │       └── pool.ts   ← Conexión a PostgreSQL (pool reutilizable)
│   └── server.ts         ← Punto de entrada del servidor Express
├── .env                  ← Variables locales (NO se commitea)
├── .env.example          ← Plantilla de variables (SÍ se commitea)
├── package.json
└── tsconfig.json
```

**Por qué `src/shared/db/pool.ts` y no conectar directo en cada archivo:**
Un Pool de conexiones es un recurso caro. Si cada módulo creara su propia conexión, terminaríamos con cientos de conexiones abiertas. Centralizarlo en un archivo y exportar la función `query` garantiza que toda la app comparte el mismo pool.

---

#### Decisiones del schema.sql

**Por qué `CHECK` constraints en `plan` y `status`:**
```sql
plan TEXT NOT NULL DEFAULT 'starter'
     CHECK (plan IN ('starter', 'growth', 'executive'))
```
Esto garantiza a nivel de base de datos que solo existan valores válidos. Si el código tiene un bug y intenta insertar `plan = 'gratis'`, la base de datos lo rechaza con un error. Es una red de seguridad adicional.

**Por qué `TIMESTAMPTZ` y no `TIMESTAMP`:**
`TIMESTAMPTZ` (timestamp con zona horaria) guarda el momento exacto en UTC internamente. Cuando el servidor o la base de datos cambian de zona horaria, los datos siguen siendo correctos. `TIMESTAMP` sin zona horaria puede generar inconsistencias si los servidores están en distintas zonas.

**Por qué el trigger `update_updated_at`:**
```sql
CREATE TRIGGER tenants_updated_at
  BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```
Sin el trigger, habría que acordarse de actualizar `updated_at` manualmente en cada UPDATE del código. El trigger lo hace automáticamente a nivel de base de datos, sin importar quién o qué actualice la fila.

**Por qué JSONB para `settings`, `hours`, `services`, `faqs`:**
Estas estructuras varían por negocio. Un consultorio tiene horarios distintos a una peluquería. Los servicios de un taller no se parecen a los de una estética. JSONB permite guardar estas estructuras flexibles sin crear una tabla nueva para cada variante. PostgreSQL puede además indexar y consultar dentro del JSONB si es necesario.

---

#### Validación de entorno con Zod (env.ts)

```typescript
const envSchema = z.object({
  DATABASE_URL: z.string().min(1, 'DATABASE_URL es requerida'),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET debe tener al menos 32 caracteres'),
  // ...
});

const parsed = envSchema.safeParse(process.env);
if (!parsed.success) {
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);  // El servidor no arranca si falta algo crítico
}
```

**Por qué esto es importante:** sin esta validación, el servidor arranca aunque falte `DATABASE_URL`. El error aparece horas después cuando alguien intenta hacer un query. Con la validación, el error aparece al segundo de intentar arrancar y dice exactamente qué falta.

**Nota sobre Zod v4:** en Zod v3 se usaba `z.string({ required_error: 'mensaje' })`. En Zod v4 eso cambió — ahora se usa `z.string().min(1, 'mensaje')`. Esta es una breaking change (cambio que rompe compatibilidad) que descubrimos al compilar.

---

#### Cómo correr el schema en PostgreSQL

```bash
# Opción 1: desde terminal con psql
psql -U postgres -d kairo_dev -f apps/api/db/schema.sql

# Opción 2: desde pgAdmin o TablePlus
# Abrir el archivo schema.sql y ejecutarlo en la base de datos kairo_dev

# Verificar que las tablas se crearon:
psql -U postgres -d kairo_dev -c "\dt"
```

---

---

### Issue #2 — Endpoint de registro (POST /api/auth/register)

**Branch:** `feature/KAI-02-auth-registro`

#### Archivos creados

```
src/modules/auth/
├── auth.schema.ts      ← Validación Zod del body del request
├── auth.types.ts       ← Tipos TypeScript (AuthResponse, JwtPayload)
├── auth.service.ts     ← Lógica de negocio (transacción, hash, JWT)
├── auth.controller.ts  ← Handler HTTP (recibe request, responde)
└── auth.routes.ts      ← Define los endpoints del módulo

src/shared/lib/
└── jwt.ts              ← signToken y verifyToken centralizados
```

#### El patrón Routes → Controller → Service

```
Request HTTP
    ↓
auth.routes.ts      → define qué función maneja qué URL
    ↓
auth.controller.ts  → valida entrada, maneja errores HTTP
    ↓
auth.service.ts     → lógica de negocio pura (no sabe de HTTP)
    ↓
base de datos
```

**Por qué esta separación:**
- El **service** no sabe que existe Express. Si mañana cambiamos Express por otro framework, el service no cambia.
- El **controller** no tiene lógica de negocio. Solo traduce entre HTTP y el service.
- El **schema** valida los datos antes de que lleguen al service. El service nunca recibe datos sucios.

---

#### Transacciones en PostgreSQL

```typescript
const client = await pool.connect(); // tomar conexión dedicada del pool

try {
  await client.query('BEGIN');        // iniciar transacción

  // operaciones...
  await client.query('INSERT INTO tenants ...');
  await client.query('INSERT INTO business_profiles ...');
  await client.query('INSERT INTO users ...');

  await client.query('COMMIT');       // confirmar todo junto
} catch (err) {
  await client.query('ROLLBACK');     // revertir si algo falló
  throw err;
} finally {
  client.release();                   // SIEMPRE devolver al pool
}
```

**Por qué `pool.connect()` y no `pool.query()` para transacciones:**
`pool.query()` puede usar cualquier conexión disponible del pool para cada llamada. Si usáramos `pool.query('BEGIN')` y luego `pool.query('INSERT...')`, esas dos llamadas podrían ir a conexiones distintas. La transacción solo existe en una conexión. Necesitamos `pool.connect()` para tener una conexión fija durante toda la transacción.

**El bloque `finally`:**
`client.release()` debe ejecutarse SIEMPRE — tanto si la operación fue exitosa como si falló. Si no liberamos el cliente, el pool se agota después de N operaciones y el servidor deja de responder. El bloque `finally` garantiza que se ejecute sin importar qué.

---

#### Hashing de passwords con bcrypt

```typescript
const SALT_ROUNDS = 12;
const passwordHash = await bcrypt.hash(input.password, SALT_ROUNDS);
```

**Cómo funciona bcrypt:**
1. Genera un "salt" (cadena aleatoria) único para este password
2. Combina password + salt y aplica el algoritmo 2^12 veces
3. El resultado incluye el salt dentro del hash

```
$2a$12$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
      ↑↑                                ↑
      12 rondas                    salt incluido
```

**Por qué no MD5 o SHA256 para passwords:**
MD5/SHA son rápidos por diseño (para firmar archivos). Bcrypt es lento por diseño. "Lento" aquí es una ventaja: si alguien roba la base de datos e intenta crackear los passwords por fuerza bruta, con bcrypt tardaría siglos.

**Por qué `SALT_ROUNDS = 12` y no más:**
- 10 rondas ≈ 100ms (algunos servicios lo usan)
- 12 rondas ≈ 250ms ← balance recomendado para APIs web
- 14 rondas ≈ 1000ms (demasiado lento para login frecuente)

---

#### JWT — Cómo funciona

```typescript
const token = jwt.sign(
  { user_id, tenant_id, role },  // payload (datos visibles, no secretos)
  env.JWT_SECRET,                 // secret para firmar
  { expiresIn: '15m' }           // vence en 15 minutos
);
```

Un JWT tiene 3 partes separadas por `.`:
```
eyJhbGciOiJIUzI1NiJ9      ← Header (algoritmo)
.eyJ1c2VyX2lkIjoiYWJjIn0  ← Payload (datos, en base64 — no cifrados)
.SflKxwRJSMeKKF2QT4fwpMeJ  ← Signature (firmada con el secret)
```

**El payload NO está cifrado** — cualquiera puede leerlo con base64. El secret solo garantiza que no fue modificado. Por eso no se ponen datos sensibles (passwords, números de tarjeta) en el JWT.

**Por qué expira en 15 minutos:**
Si alguien roba el token, tiene acceso por 15 minutos máximo. En el issue #3 (login) se implementa el refresh token para renovarlo sin pedir password de nuevo.

---

#### Validación de entrada con Zod y manejo de errores

```typescript
// En el controller:
const parsed = registerSchema.safeParse(req.body);

if (!parsed.success) {
  res.status(400).json({
    error: 'Datos inválidos',
    details: parsed.error.flatten().fieldErrors,
  });
  return;
}
```

**`safeParse` vs `parse`:**
- `parse()` lanza una excepción si falla → hay que envolverlo en try/catch
- `safeParse()` devuelve un objeto `{ success, data | error }` → más limpio en controllers

**Respuesta 400 con detalles:**
```json
{
  "error": "Datos inválidos",
  "details": {
    "email": ["Email inválido"],
    "password": ["La contraseña debe tener al menos 8 caracteres"]
  }
}
```
El frontend puede mostrar cada error al lado del campo correspondiente.

---

#### Endpoints implementados hasta ahora

| Método | URL | Descripción | Status |
|---|---|---|---|
| GET | /health | Verificar que el servidor corre | ✅ |
| POST | /api/auth/register | Crear cuenta nueva | ✅ |
| POST | /api/auth/login | Iniciar sesión | 🔜 Issue #3 |

---

*Este manual fue generado al inicio del proyecto Kairo AI — Abril 2026.*
