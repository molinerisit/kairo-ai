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
Configurar en el dashboard de Railway → Variables:

```
NODE_ENV=production
DATABASE_URL=           # Provista automáticamente al agregar plugin PostgreSQL
JWT_SECRET=             # Generar con: node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
ALLOWED_ORIGIN=https://kairo-web-ashen.vercel.app
ANTHROPIC_API_KEY=      # Conseguir en console.anthropic.com
WHATSAPP_VERIFY_TOKEN=  # Token secreto que vos definís — debe coincidir con Meta dashboard
WHATSAPP_ACCESS_TOKEN=  # Token de acceso de la app de Meta (EAAn...)
WHATSAPP_PHONE_NUMBER_ID= # ID del número de teléfono en Meta (ej: 1162594183593578)
META_APP_SECRET=        # App Secret de la app de Meta (para verificar firma HMAC)
```

### Cómo deployar
Railway hace deploy automático al hacer push a `main` si está conectado al repo de GitHub.
Para deploy manual desde CLI:
```bash
railway up
```

---

## Frontend — Vercel

### Configuración (`apps/web/vercel.json`)
- Rewrites: todas las rutas apuntan a `index.html` (SPA routing)
- Cache: assets estáticos cacheados 1 año (immutable)

### Variables de entorno en Vercel
Configurar en el dashboard de Vercel → Settings → Environment Variables:

```
FLUTTER_API_URL=    # URL base del backend en Railway
```

### Cómo deployar
Vercel hace deploy automático al hacer push a `main` si está conectado al repo de GitHub.
Para deploy manual:
```bash
cd apps/web
flutter build web
vercel --prod
```

---

## WhatsApp Business API — Configuración del Webhook

### Datos de la app Meta
- **Phone Number ID:** `1162594183593578`
- **Access Token:** guardado en `WHATSAPP_ACCESS_TOKEN`

### Configurar webhook en Meta for Developers

1. Ir a [Meta for Developers](https://developers.facebook.com) → Tu App → WhatsApp → Configuration
2. En **Webhook**:
   - **Callback URL:** `https://kairo-api-production-5af7.up.railway.app/api/webhook/whatsapp`
   - **Verify Token:** el valor de `WHATSAPP_VERIFY_TOKEN` en Railway
3. Hacer clic en **Verify and Save**
4. Suscribirse al campo **messages**

### Cómo funciona el webhook
```
Meta (mensaje entrante)
  → POST /api/webhook/whatsapp
  → Verifica firma HMAC con META_APP_SECRET
  → Responde 200 inmediatamente
  → Procesa mensaje de forma asíncrona
```

### Endpoint de verificación (GET)
Meta llama a este endpoint al configurar el webhook:
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
  → Agente IA (Anthropic Claude)
  → Respuesta vía WhatsApp API
  → Usuario final

Operador del negocio (Panel web)
  → https://kairo-web-ashen.vercel.app  (Vercel)
  → REST API en Railway
  → PostgreSQL en Railway
```

---

## Seguridad en producción

- `META_APP_SECRET`: el backend verifica que cada request del webhook viene realmente de Meta usando HMAC-SHA256. Sin esto configurado, el servidor acepta cualquier request (solo en dev).
- `JWT_SECRET`: debe ser un string aleatorio de al menos 48 caracteres, diferente al de dev.
- `WHATSAPP_VERIFY_TOKEN`: puede ser cualquier string secreto — solo Meta y vos lo saben.
