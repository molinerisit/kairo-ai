import Anthropic from '@anthropic-ai/sdk';
import { env } from '../../config/env';

// Instancia única del cliente de Anthropic (Singleton pattern).
// Se crea una sola vez y se reutiliza en todas las llamadas.
// Si no hay API key configurada, lanza error descriptivo en el momento de uso.
let _client: Anthropic | null = null;

function getClient(): Anthropic {
  if (!_client) {
    if (!env.ANTHROPIC_API_KEY) {
      throw new Error(
        '[AI] ANTHROPIC_API_KEY no configurada. ' +
        'Agregá ANTHROPIC_API_KEY=sk-ant-... al archivo .env'
      );
    }
    _client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  }
  return _client;
}

// Tipos que usamos para estructurar el historial de mensajes.
// Son compatibles con el formato de la API de Claude y nuestra tabla messages.
export interface ChatMessage {
  role:    'user' | 'assistant';
  content: string;
}

export interface AiCallOptions {
  systemPrompt: string;          // instrucciones del agente (personalidad, contexto del negocio)
  messages:     ChatMessage[];   // historial de la conversación
  maxTokens?:   number;          // límite de tokens en la respuesta
  model?:       string;          // modelo a usar (default: claude-haiku-4-5 — rápido y económico)
}

export interface AiCallResult {
  content:     string;
  tokensUsed:  number;
  latencyMs:   number;
}

// callClaude: función central que todos los agentes usan para llamar a la IA.
// Registra latencia y tokens para monitoreo de costos.
export async function callClaude(options: AiCallOptions): Promise<AiCallResult> {
  const client = getClient();
  const startMs = Date.now();

  // claude-haiku-4-5 es el modelo más rápido y económico de la familia Claude.
  // Para el primer agente es ideal: respuestas en <1 segundo, costo mínimo.
  // Si se necesita más capacidad de razonamiento, se puede subir a claude-sonnet-4-6.
  const model = options.model ?? 'claude-haiku-4-5-20251001';

  const response = await client.messages.create({
    model,
    max_tokens: options.maxTokens ?? 1024,
    system:     options.systemPrompt,
    messages:   options.messages,
  });

  const latencyMs  = Date.now() - startMs;
  const content    = response.content[0].type === 'text' ? response.content[0].text : '';
  const tokensUsed = response.usage.input_tokens + response.usage.output_tokens;

  return { content, tokensUsed, latencyMs };
}
