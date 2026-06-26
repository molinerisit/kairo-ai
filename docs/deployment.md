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
> ⚠️ El servicio Railway `kairo-api` **NO está conectado a GitHub** — un `git push`
> a `main` **no** dispara deploy. Hay que deployar a mano con el CLI:
```bash
cd apps/api
railway up                       # builda (Nixpacks) y deploya el código local
```
- Dominio público real: **`https://kairo-api-production-c547.up.railway.app`**
  (sale de la env `RAILWAY_PUBLIC_DOMAIN`; el `-5af7` viejo de esta doc quedó
  desactualizado).
- `OPENAI_API_KEY` debe estar seteada o el agente no responde.

---

## Frontend — Vercel

> ⚠️ **Leer esto entero antes de deployar el frontend.** Hay varias trampas que
> ya rompieron producción una vez. Documentado el 2026-06-26.

### Datos del proyecto
- **Proyecto Vercel:** `kairo-web` · **scope:** `julianmolineris-projects`
  (cuenta `julianmolinerisonline@gmail.com`).
- **Dominio:** usar **`https://www.getaxiia.com`**. El apex `getaxiia.com` está
  **parked en Hostinger** (no apunta a Vercel) — si lo abrís a secas ves una
  página de Hostinger, no la app. Para arreglarlo: apuntar el A/ALIAS del apex a
  Vercel en el DNS de Hostinger.
- URL técnica de Vercel: `https://kairo-web-ashen.vercel.app`.

### ‼️ El proyecto NO compila Flutter en Vercel
La config de Vercel tiene `buildCommand`, `outputDirectory` y `rootDirectory`
**vacíos**. Vercel **sirve estáticamente** lo que se sube — NO corre
`flutter build`. Por eso un `git push` de código **no actualiza el sitio** por sí
solo; hay que subir el `build/web` ya compilado.

### Cómo deployar (procedimiento correcto)
```bash
# 1. Compilar localmente
cd apps/web
flutter build web --no-tree-shake-icons

# 2. Deployar el build estático A PRODUCCIÓN desde build/web
cd build/web
vercel --prod --yes --scope julianmolineris-projects
```
- El `apps/web/build/web/vercel.json` define los **rewrites SPA** y los **headers
  de caché**. Se sube junto con el build.
- Si el CLI está logueado en otra cuenta (ej. `banana24hs`), correr
  `vercel login` con la cuenta de Axiia y linkear: 
  `vercel link --yes --project kairo-web --scope julianmolineris-projects`.

### ❌ NO hacer
- **NO** `vercel --prod` desde la **raíz del repo** → sube archivos crudos del
  repo (sin compilar) y **rompe producción** (el sitio queda en 404 / listado de
  archivos). Siempre deployar desde `apps/web/build/web`.
- **NO** marcar `main.dart.js` / `flutter_bootstrap.js` como `immutable` en los
  headers de caché. Flutter NO les cambia el nombre entre builds, así que el
  browser se queda con la versión vieja **para siempre** (ver troubleshooting).
  Deben ir `Cache-Control: public, max-age=0, must-revalidate`.

### Rollback (si un deploy rompe prod)
```bash
# Listar deploys y promover uno bueno a producción
vercel ls kairo-web --scope julianmolineris-projects
vercel promote <url-del-deploy-bueno> --yes --scope julianmolineris-projects
```

### 🛠 Troubleshooting: "deployé pero el sitio se ve viejo / oscuro / sin cambios"
Casi siempre es **caché HTTP del `main.dart.js`** (no un problema del deploy).
1. Confirmar que el server SÍ tiene el build nuevo (comparar hashes):
   ```bash
   md5sum apps/web/build/web/main.dart.js
   curl -s https://www.getaxiia.com/main.dart.js | md5sum   # debe coincidir
   ```
2. Verificar que el header NO sea `immutable`:
   ```bash
   curl -sI https://www.getaxiia.com/main.dart.js | grep -i cache-control
   # esperado: public, max-age=0, must-revalidate
   ```
3. En el browser: **`Ctrl + Shift + R`** (hard refresh) una vez. Si seguís con
   la versión vieja, el `main.dart.js` quedó cacheado `immutable` de un deploy
   anterior → redeployar con el header corregido y hard-refresh.
4. Para confirmar que es caché y no el build: en DevTools, en
   `performance.getEntriesByType('resource')` el `main.dart.js` con
   `transferSize: 0` significa que vino de caché, no de la red.

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
