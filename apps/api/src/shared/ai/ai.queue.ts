import { Queue, Worker, QueueEvents } from 'bullmq';
import { env } from '../../config/env';
import { callOpenAI, type AiCallOptions, type AiCallResult } from './openai.client';

// ai.queue.ts — Cola de llamadas IA con BullMQ + Redis.
//
// Por qué una cola:
//   - OpenAI limita por RPM/TPM por API key.
//   - En un SaaS, múltiples tenants pueden hacer llamadas simultáneas.
//   - La cola serializa las llamadas con concurrencia controlada (3 workers)
//     y retries automáticos si un job falla por 429.
//
// Modo fallback:
//   - Si REDIS_URL no está configurada (dev local sin Redis), llama a
//     callOpenAI() directamente con exponential backoff.
//   - En producción REDIS_URL siempre debe estar configurada.

const QUEUE_NAME = 'ai-calls';

// Conexión a Redis para BullMQ.
// Railway expone Redis con una URL completa (redis://...).
function getRedisConnection() {
  if (!env.REDIS_URL) return null;
  return { url: env.REDIS_URL };
}

let _queue:        Queue<AiCallOptions, AiCallResult>       | null = null;
let _queueEvents:  QueueEvents                               | null = null;

function getQueue() {
  const conn = getRedisConnection();
  if (!conn) return null;

  if (!_queue) {
    _queue = new Queue<AiCallOptions, AiCallResult>(QUEUE_NAME, {
      connection: conn,
      defaultJobOptions: {
        attempts:        3,
        backoff:         { type: 'exponential', delay: 2000 },
        removeOnComplete: 100,  // conserva últimos 100 completados para debug
        removeOnFail:     50,
      },
    });

    _queueEvents = new QueueEvents(QUEUE_NAME, { connection: conn });

    // Worker: procesa llamadas IA.
    // concurrency: 3 → máximo 3 llamadas en paralelo a OpenAI.
    // Ajustar según el tier de la API key (Tier 1 = 500 RPM, más que suficiente).
    new Worker<AiCallOptions, AiCallResult>(
      QUEUE_NAME,
      async (job) => callOpenAI(job.data),
      { connection: conn, concurrency: 3 }
    );

    console.log('[AI Queue] BullMQ iniciado (Redis conectado)');
  }

  return { queue: _queue, queueEvents: _queueEvents! };
}

// callAI: punto de entrada para todos los agentes.
//
// Con Redis    → encola el trabajo y espera el resultado (hasta 30s timeout).
// Sin Redis    → llama a OpenAI directamente con retry (modo dev/fallback).
//
// Incluye el tenantId en el job name para trazabilidad en el panel de Bull.
export async function callAI(
  options:  AiCallOptions,
  tenantId?: string,
): Promise<AiCallResult> {
  const queueCtx = getQueue();

  if (!queueCtx) {
    // Fallback: sin Redis, llamada directa
    return callOpenAI(options);
  }

  const { queue, queueEvents } = queueCtx;
  const jobName = tenantId ? `tenant:${tenantId}` : 'call';

  const job = await queue.add(jobName, options);
  return job.waitUntilFinished(queueEvents, 30_000);
}
