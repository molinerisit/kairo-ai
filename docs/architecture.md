# Arquitectura Técnica — Kairo AI

## Visión general

Kairo AI es un sistema multi-tenant (múltiples clientes aislados en una misma plataforma) donde cada negocio opera de forma completamente separada. El canal principal de interacción es WhatsApp, y el panel de control es una web app en Flutter.

---

## Capas del sistema

```
┌─────────────────────────────────────────────────────────┐
│                   CANALES DE ENTRADA                    │
│         WhatsApp Business API  |  Panel Web             │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────┐
│               ORQUESTADOR (API Node.js)                 │
│  Recibe, clasifica y despacha cada mensaje/acción       │
└──────┬──────────────────────┬──────────────────────┬────┘
       │                      │                      │
┌──────▼──────┐    ┌──────────▼──────┐    ┌──────────▼──┐
│   AGENTES   │    │   DATOS         │    │  AUTOMATIZ. │
│  Secretario │    │  Tabla dinámica │    │  Recordat.  │
│  Vendedor   │    │  Conversaciones │    │  Seguim.    │
│  Soporte    │    │  Clientes       │    │  Alertas    │
└──────┬──────┘    └──────────┬──────┘    └──────────┬──┘
       │                      │                      │
┌──────▼──────────────────────▼──────────────────────▼────┐
│               CAPA DE DATOS                             │
│     PostgreSQL + JSONB  |  Redis (cache / jobs)         │
└─────────────────────────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────────────────┐
│               CAPA DE IA                               │
│  Clasificación (modelo barato) | Respuesta (mod. medio) │
│  Extracción de datos | Resúmenes | Cache de prompts     │
└─────────────────────────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────────────────┐
│               AUDITORÍA Y LOGS                         │
│  Registro de cada acción automática con su razón       │
└─────────────────────────────────────────────────────────┘
```

---

## Componentes principales

### Backend (Node.js modular)

Organizado por dominios, no por capas técnicas:

```
apps/api/src/
├── modules/
│   ├── auth/          # Autenticación y JWT
│   ├── tenants/       # Gestión de negocios (multi-tenant)
│   ├── users/         # Usuarios y roles
│   ├── conversations/ # Mensajes y estados
│   ├── tables/        # Tablas dinámicas
│   ├── calendar/      # Eventos y calendario
│   ├── agents/        # Motor de agentes IA
│   ├── automations/   # Reglas y automatizaciones
│   └── billing/       # Suscripciones y uso
├── shared/
│   ├── middleware/    # Auth, tenant, rate-limit
│   ├── queue/         # Trabajos en segundo plano (Redis)
│   └── ai/            # Servicios de IA centralizados
└── config/
```

### Frontend (Flutter Web)

```
apps/web/lib/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── tables/        # Tabla dinámica tipo Excel
│   ├── calendar/
│   ├── conversations/ # Bandeja de conversaciones
│   └── settings/
├── shared/
│   ├── widgets/       # Componentes reutilizables
│   ├── theme/
│   └── services/      # Llamadas a la API
```

---

## Multi-tenancy (aislamiento de datos por cliente)

Cada tabla de la base de datos tiene `tenant_id`. El middleware del backend verifica el token JWT (JSON Web Token — credencial cifrada de sesión), extrae el `tenant_id` y lo aplica automáticamente a todas las queries (consultas a la base de datos).

```
Request → Middleware extrae tenant_id del JWT
        → Todas las queries incluyen WHERE tenant_id = ?
        → Ningún negocio puede ver datos de otro
```

---

## Autenticación (verificación de identidad)

Flujo:
1. Usuario envía email + password
2. Backend verifica en tabla `users`
3. Si válido, genera JWT firmado con `tenant_id` + `role` + `user_id`
4. El token se envía en cada request como `Authorization: Bearer <token>`
5. El middleware valida el token en cada endpoint protegido

Roles:
- `superadmin` — acceso total a todos los tenants
- `owner` — acceso solo a su tenant
- `operator` — acceso limitado dentro de su tenant

---

## Estrategia de IA

| Tarea | Modelo | Razón |
|---|---|---|
| Clasificar intención | Modelo económico (ej. haiku) | Alta frecuencia, baja complejidad |
| Extraer datos (nombre, fecha, servicio) | Modelo económico | Tarea estructurada |
| Generar respuesta visible al cliente | Modelo medio (ej. sonnet) | Calidad de escritura |
| Resumen diario | Modelo económico | Tarea de batch |

Regla central: **todo lo que puede resolverse con una regla o template no pasa por IA.**

---

## Jobs en segundo plano (Redis + queue)

Tareas que no deben bloquear una request HTTP (pedido web):
- Envío de recordatorios de citas
- Seguimiento automático de leads sin respuesta
- Generación del resumen diario
- Cambio automático de estados por tiempo

---

## Seguridad

- Passwords hasheados con bcrypt
- JWT con expiración corta + refresh token
- Rate limiting por IP y por tenant
- Validación de inputs en cada endpoint
- Ningún dato de un tenant accesible desde otro
