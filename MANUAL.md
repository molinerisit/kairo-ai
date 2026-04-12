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

*Este manual fue generado al inicio del proyecto Kairo AI — Abril 2026.*
