# Kairo AI

SaaS de asistentes digitales para negocios. Secretario, vendedor y soporte que actúan por WhatsApp con tono humano, memoria operativa y costo controlado.

## Stack

| Capa | Tecnología |
|---|---|
| Frontend | Flutter Web |
| Backend | Node.js (modular, Express) |
| Base de datos | PostgreSQL + JSONB |
| Cache / Jobs | Redis |
| Canal principal | WhatsApp Business API |

## Estructura del proyecto

```
kairos/
├── apps/
│   ├── web/        # Flutter Web — panel de control del negocio
│   └── api/        # Node.js — backend modular
├── docs/
│   ├── architecture.md   # Arquitectura técnica detallada
│   ├── data-model.md     # Modelo de datos y schema
│   └── workflow.md       # Flujo de trabajo y convenciones
├── .github/
│   ├── workflows/        # CI/CD (Integración y despliegue continuo)
│   └── PULL_REQUEST_TEMPLATE.md
└── MANUAL.md             # Manual profesional del proyecto
```

## Documentación

- [Manual del proyecto](./MANUAL.md)
- [Arquitectura técnica](./docs/architecture.md)
- [Modelo de datos](./docs/data-model.md)
- [Workflow de desarrollo](./docs/workflow.md)
- [Deployment e infraestructura](./docs/deployment.md)

## Cómo empezar

```bash
# Backend
cd apps/api
npm install
npm run dev

# Frontend
cd apps/web
flutter pub get
flutter run -d chrome
```
