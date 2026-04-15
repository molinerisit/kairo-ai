# Deployment e Infraestructura — Kairo AI

## Servicios en producción

| Capa | Servicio | URL |
|---|---|---|
| Frontend (Flutter Web) | Vercel | https://kairo-web-ashen.vercel.app |
| Backend (Node.js API) | Railway | https://kairo-api-production-5af7.up.railway.app |
| Base de datos | Railway PostgreSQL | Provista automáticamente por Railway |
| WhatsApp | Meta — WhatsApp Business API | graph.facebook.com/v25.0 |

---

## Backend — Railway

### Configuración (`apps/api/railway.json`)
- Builder: Nixpacks (detecta Node.js automáticamente)
- Start command: `npm start`
- Healthcheck: `GET /health`
- Restart policy: ON_FAILURE, máx 3 reintentos

### Variables de entorno en Railway
Estado actual (todas configuradas):

```
NODE_ENV=production              ✓
DATABASE_URL=                    ✓ (Railway PostgreSQL plugin)
JWT_SECRET=                      ✓
JWT_EXPIRES_IN=15m               ✓
JWT_REFRESH_EXPIRES_IN=7d        ✓
ALLOWED_ORIGIN=https://kairo-web-ashen.vercel.app  ✓
BASE_URL=https://kairo-api-production-5af7.up.railway.app  ✓
OPENAI_API_KEY=                  ✓
WHATSAPP_VERIFY_TOKEN=kairo_webhook_secret_prod     ✓
WHATSAPP_ACCESS_TOKEN=EAAn...    ✓
WHATSAPP_PHONE_NUMBER_ID=1162594183593578           ✓
META_APP_SECRET=                 ✓
```

### Cómo deployar
Railway hace deploy automático al hacer push a `main`.
Para deploy manual desde CLI:
```bash
railway up
```

---

## Frontend — Vercel

### Configuración (`apps/web/vercel.json`)
- Rewrites: todas las rutas apuntan a `index.html` (SPA routing)
- Cache: assets estáticos cacheados 1 año (immutable)

### Cómo deployar
Vercel hace deploy automático al hacer push a `main`.
Para deploy manual:
```bash
cd apps/web
flutter build web
vercel --prod
```

---

## WhatsApp Business API

### Datos de la app Meta
- **App ID:** `2750786518653266`
- **Phone Number ID:** `1162594183593578`
- **Access Token:** guardado en `WHATSAPP_ACCESS_TOKEN` (Railway)
- **App Secret:** guardado en `META_APP_SECRET` (Railway)
- **Verify Token:** `kairo_webhook_secret_prod`

### Webhook configurado
- **Callback URL:** `https://kairo-api-production-5af7.up.railway.app/api/webhook/whatsapp`
- **Campo suscripto:** `messages`
- **Versión API:** v25.0
- **Estado:** verificado y activo

### Cómo funciona el webhook
```
Usuario final escribe por WhatsApp
  → Meta WhatsApp Cloud API
  → POST /api/webhook/whatsapp  (Railway)
  → Verifica firma HMAC con META_APP_SECRET
  → Responde 200 inmediatamente
  → Agente secretario (OpenAI GPT-4o-mini)
  → sendWhatsAppMessage() → respuesta al usuario
```

### Endpoint de verificación (GET)
```
GET /api/webhook/whatsapp?hub.mode=subscribe&hub.verify_token=XXX&hub.challenge=YYY
```
El servidor responde con `hub.challenge` si el token coincide.

---

## Flujo de datos completo

```
Usuario final (WhatsApp)
  → Meta WhatsApp Cloud API
  → POST /api/webhook/whatsapp  (Railway)
  → Agente secretario (OpenAI)
  → Respuesta vía WhatsApp API
  → Usuario final

Operador del negocio (Panel web)
  → https://kairo-web-ashen.vercel.app  (Vercel)
  → REST API en Railway
  → PostgreSQL en Railway
```

---

## Seguridad en producción

- `META_APP_SECRET`: verifica que cada request del webhook viene de Meta usando HMAC-SHA256.
- `JWT_SECRET`: string aleatorio de 48+ caracteres, diferente al de dev.
- `WHATSAPP_VERIFY_TOKEN`: solo Meta y el servidor lo conocen.

---

## Estado al 2025-04-15 — Punto de retoma

### Lo que está hecho y funcionando
- [x] Backend corriendo en Railway con todas las variables configuradas
- [x] Frontend deployado en Vercel
- [x] Webhook de WhatsApp verificado y suscripto al campo `messages`
- [x] Verificación HMAC con META_APP_SECRET activa en producción
- [x] Agente secretario implementado (OpenAI GPT-4o-mini)

### Pendiente — próximo paso
- [ ] **Publicar la app en Meta** (actualmente en modo desarrollo)
  - Mientras esté en dev, solo admins/devs/testers pueden recibir mensajes
  - Ir a Meta for Developers → Tu App → **App Review** o botón **"Go Live"**
  - Necesita: política de privacidad, ícono de app, descripción
  - La URL de privacidad puede ser la página de privacidad del sitio web de Kairo

- [ ] Registrar el número de producción en `business_profiles` de la DB
  - El webhook busca el tenant por `whatsapp_phone_number_id`
  - Sin ese registro en la DB, los mensajes llegan pero no se procesan
  - Query: `INSERT INTO business_profiles (tenant_id, whatsapp, ...) VALUES (...)`

- [ ] Probar el flujo completo end-to-end con un mensaje real desde WhatsApp
