import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env';
import authRoutes from './modules/auth/auth.routes';

const app = express();

// ── Middlewares globales ──────────────────────────────────────────
// helmet: agrega headers de seguridad HTTP automáticamente
app.use(helmet());

// cors: permite que el frontend (Flutter Web) llame a esta API
// En producción, reemplazar origin por el dominio real
app.use(cors({
  origin: env.NODE_ENV === 'production'
    ? 'https://app.kairoai.com'
    : 'http://localhost:8080',
  credentials: true,
}));

// express.json: parsea el body de las requests como JSON
app.use(express.json());

// ── Rutas ─────────────────────────────────────────────────────────
// Montamos cada módulo con su prefijo.
// Todos los endpoints de auth quedan bajo /api/auth/
app.use('/api/auth', authRoutes);

// ── Health check ────────────────────────────────���─────────────────
// Endpoint simple para verificar que el servidor está corriendo.
// Usado por CI/CD y servicios de monitoreo.
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', env: env.NODE_ENV, timestamp: new Date().toISOString() });
});

// ── Arrancar servidor ─────────────────────────────────────────────
const PORT = parseInt(env.PORT, 10);

app.listen(PORT, () => {
  console.log(`[Server] Corriendo en http://localhost:${PORT}`);
  console.log(`[Server] Entorno: ${env.NODE_ENV}`);
});

export default app;
