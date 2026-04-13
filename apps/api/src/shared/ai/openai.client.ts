import OpenAI from 'openai';
import { env } from '../../config/env';

// Singleton del cliente OpenAI.
// Se inicializa la primera vez que se llama a getClient().
let _client: OpenAI | null = null;

function getClient(): OpenAI {
  if (!_client) {
    if (!env.OPENAI_API_KEY) {
      throw new Error(
        '[AI] OPENAI_API_KEY no configurada. ' +
        'Agregá OPENAI_API_KEY=sk-proj-... a las variables de entorno.'
      );
    }
    _client = new OpenAI({ apiKey: env.OPENAI_API_KEY });
  }
  return _client;
}

export interface ChatMessage {
  role:    'user' | 'assistant';
  content: string;
}

export interface AiCallOptions {
  systemPrompt: string;
  messages:     ChatMessage[];
  maxTokens?:   number;
  model?:       string;
}

export interface AiCallResult {
  content:    string;
  tokensUsed: number;
  latencyMs:  number;
}

// callOpenAI: llama a GPT-4o-mini con retry en 429 (exponential backoff).
// Reintentos: hasta 3 veces con delays de 2s, 4s, 8s.
// Todos los agentes del sistema usan esta función como punto de entrada a la IA.
export async function callOpenAI(options: AiCallOptions, attempt = 1): Promise<AiCallResult> {
  const client  = getClient();
  const startMs = Date.now();
  const model   = options.model ?? 'gpt-4o-mini';

  try {
    const response = await client.chat.completions.create({
      model,
      max_tokens:  options.maxTokens ?? 500,
      temperature: 0.7,
      messages: [
        { role: 'system', content: options.systemPrompt },
        ...options.messages,
      ],
    });

    const content    = response.choices[0]?.message?.content ?? '';
    const tokensUsed = response.usage?.total_tokens ?? 0;

    return { content, tokensUsed, latencyMs: Date.now() - startMs };

  } catch (err: unknown) {
    // 429 Rate Limit → exponential backoff, máx 3 intentos
    const status = (err as { status?: number })?.status;
    if (status === 429 && attempt <= 3) {
      const delayMs = Math.pow(2, attempt) * 1000; // 2s → 4s → 8s
      console.warn(`[AI] Rate limit (intento ${attempt}/${3}), reintentando en ${delayMs}ms`);
      await new Promise(r => setTimeout(r, delayMs));
      return callOpenAI(options, attempt + 1);
    }
    throw err;
  }
}
