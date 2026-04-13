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
import { authMiddleware } from './shared/middleware/auth.middleware';

const app = express();

// ── Middlewares globales ──────────────────────────────────────────
// helmet: agrega headers de seguridad HTTP automáticamente
app.use(helmet());

// cors: permite que el frontend (Flutter Web) llame a esta API
// En producción, reemplazar origin por el dominio real
app.use(cors({
  origin: env.ALLOWED_ORIGIN ?? (env.NODE_ENV === 'production'
    ? 'https://kairo-web.vercel.app'
    : 'http://localhost:8080'),
  credentials: true,
}));

// express.json: parsea el body de las requests como JSON
app.use(express.json());

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

// ── Health check ────────────────────────────────���─────────────────
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
