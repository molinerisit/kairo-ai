import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env';
import authRoutes          from './modules/auth/auth.routes';
import tablesRoutes        from './modules/tables/tables.routes';
import conversationsRoutes from './modules/conversations/conversations.routes';
import calendarRoutes      from './modules/calendar/calendar.routes';
import agentsRoutes        from './modules/agents/agents.routes';
import webhookRoutes       from './modules/webhook/webhook.routes';
import { statsController } from './modules/stats/stats.controller';
import businessProfileRoutes from './modules/business-profile/business-profile.routes';
import whatsappConnectRoutes from './modules/whatsapp-connect/whatsapp-connect.routes';
import { authMiddleware } from './shared/middleware/auth.middleware';

const app = express();

// ── Middlewares globales ──────────────────────────────────────────
// helmet: agrega headers de seguridad HTTP automáticamente
app.use(helmet());

// cors: permite que el frontend (Flutter Web) llame a esta API
// Acepta la URL de producción de Vercel, cualquier preview deploy (*.vercel.app)
// y localhost en desarrollo.
const ALLOWED_ORIGINS = [
  env.ALLOWED_ORIGIN,
  'https://getaxiia.com',
  'https://www.getaxiia.com',
  'https://kairo-web-ashen.vercel.app',
  'http://localhost:8080',
].filter(Boolean) as string[];

app.use(cors({
  origin: (origin, callback) => {
    // Sin origin (ej: curl, Postman) o dominio permitido exacto
    if (!origin || ALLOWED_ORIGINS.includes(origin)) return callback(null, true);
    // Preview deploys de Vercel: *.vercel.app
    if (origin.endsWith('.vercel.app')) return callback(null, true);
    callback(new Error(`CORS: origin no permitido: ${origin}`));
  },
  credentials: true,
}));

// express.json: parsea el body de las requests como JSON.
// La opción `verify` captura el raw body buffer para que el webhook de Meta
// pueda verificar la firma HMAC-SHA256 sobre los bytes originales.
app.use(express.json({
  verify: (req: any, _res, buf) => {
    req.rawBody = buf;
  },
}));

// ── Rutas ─────────────────────────────────────────────────────────
// Montamos cada módulo con su prefijo.
// Todos los endpoints de auth quedan bajo /api/auth/
app.use('/api/auth',          authRoutes);
app.use('/api/tables',       tablesRoutes);
app.use('/api/conversations', conversationsRoutes);
app.use('/api/calendar',     calendarRoutes);
app.use('/api/conversations', agentsRoutes);
app.use('/api/webhook',      webhookRoutes);
app.get('/api/stats',        authMiddleware, statsController);
app.use('/api/business-profile', businessProfileRoutes);
app.use('/api/whatsapp',        whatsappConnectRoutes);

// ── Data Deletion Callback (Meta requerido) ───────────────────────
// Meta llama a este endpoint cuando un usuario revoca permisos de la app.
// Debe responder con { url, confirmation_code } para que Meta muestre
// al usuario dónde puede ver el estado de su solicitud.
app.post('/api/data-deletion', (req, res) => {
  const { createHmac, randomBytes } = require('crypto');
  const appSecret = env.META_APP_SECRET;
  const signedRequest = req.body?.signed_request as string | undefined;

  if (appSecret && signedRequest) {
    try {
      const [encodedSig, payload] = signedRequest.split('.');
      const expectedSig = createHmac('sha256', appSecret)
        .update(payload)
        .digest('base64url');
      if (encodedSig !== expectedSig) {
        res.status(400).json({ error: 'Invalid signature' });
        return;
      }
    } catch {
      res.status(400).json({ error: 'Malformed signed_request' });
      return;
    }
  }

  const confirmationCode = randomBytes(8).toString('hex');
  res.json({
    url: 'https://getaxiia.com/data-deletion',
    confirmation_code: confirmationCode,
  });
});

// ── Health check ────────────────────────────────────────────────────
// Endpoint simple para verificar que el servidor está corriendo.
// Usado por CI/CD y servicios de monitoreo.
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', env: env.NODE_ENV, timestamp: new Date().toISOString() });
});

// ── Endpoint protegido de prueba ──────────────────────────────────
// Verifica que el middleware funciona correctamente.
// GET /api/me con un JWT válido → devuelve los datos del usuario.
// GET /api/me sin token         → 401.
app.get('/api/me', authMiddleware, (req, res) => {
  res.json({ user: req.user });
});

// ── Arrancar servidor ─────────────────────────────────────────────
const PORT = parseInt(env.PORT, 10);

app.listen(PORT, () => {
  console.log(`[Server] Corriendo en http://localhost:${PORT}`);
  console.log(`[Server] Entorno: ${env.NODE_ENV}`);
});

export default app;
