import { callClaude, type ChatMessage } from '../../shared/ai/claude.client';
import { query } from '../../shared/db/pool';
import { createMessage } from '../conversations/conversations.service';

// ── TIPOS ────────────────────────────────────────────────────────────────────

interface BusinessProfile {
  tone:        string | null;
  description: string | null;
  hours:       Record<string, string>;
  services:    Array<{ name: string; price?: number }>;
  faqs:        Array<{ q: string; a: string }>;
  whatsapp:    string | null;
  address:     string | null;
}

export interface SecretaryInput {
  tenantId:       string;
  conversationId: string;
  userMessage:    string;   // el mensaje que acaba de llegar del cliente
}

export interface SecretaryOutput {
  response:    string;    // la respuesta generada
  tokensUsed:  number;
  latencyMs:   number;
}

// ── SYSTEM PROMPT ─────────────────────────────────────────────────────────────
// El system prompt define la personalidad y el conocimiento del agente.
// Se construye dinámicamente con los datos del perfil del negocio para que
// cada negocio tenga un asistente personalizado.

function buildSystemPrompt(profile: BusinessProfile): string {
  const tone    = profile.tone        ?? 'amable y profesional';
  const desc    = profile.description ?? 'un negocio';
  const address = profile.address     ?? 'consultar directamente';

  // Formateamos los horarios de forma legible
  const hoursText = Object.entries(profile.hours)
    .map(([day, hours]) => `  - ${day}: ${hours}`)
    .join('\n') || '  - Consultar por WhatsApp';

  // Formateamos los servicios con precio opcional
  const servicesText = profile.services.length > 0
    ? profile.services
        .map(s => `  - ${s.name}${s.price ? ` ($${s.price.toLocaleString('es-AR')})` : ''}`)
        .join('\n')
    : '  - Consultar por los servicios disponibles';

  // Formateamos las FAQs
  const faqsText = profile.faqs.length > 0
    ? profile.faqs
        .map(f => `  P: ${f.q}\n  R: ${f.a}`)
        .join('\n\n')
    : '';

  return `Sos el asistente virtual de ${desc}. Tu tono es ${tone}.

## Tu rol
Ayudás a los clientes respondiendo consultas, dando información del negocio y tomando turnos.
Sos servicial, conciso y usás el tono del negocio. Respondés en el mismo idioma que el cliente.
Nunca inventás información — si no sabés algo, pedís que se comuniquen directamente.

## Información del negocio
**Dirección:** ${address}

**Horarios:**
${hoursText}

**Servicios:**
${servicesText}
${faqsText ? `\n## Preguntas frecuentes\n${faqsText}` : ''}

## Instrucciones importantes
- Respondés de forma breve (2-4 oraciones máximo para mensajes de WhatsApp).
- Si el cliente quiere sacar un turno, pedís: nombre, servicio que quiere y día/horario preferido.
- Si pregunta algo que no está en tu información, decís "Te paso con el equipo para más detalles".
- No mencionés que sos IA a menos que te lo pregunten directamente.`;
}

// ── AGENTE SECRETARIO ─────────────────────────────────────────────────────────

export async function runSecretary(input: SecretaryInput): Promise<SecretaryOutput> {
  // 1. Cargar el perfil del negocio para armar el system prompt personalizado
  const profileResult = await query<BusinessProfile>(
    `SELECT tone, description, hours, services, faqs, whatsapp, address
     FROM business_profiles
     WHERE tenant_id = $1`,
    [input.tenantId]
  );

  const profile = profileResult.rows[0] ?? {
    tone: null, description: null, hours: {}, services: [], faqs: [], whatsapp: null, address: null,
  };

  // 2. Cargar el historial reciente de la conversación (últimos 20 mensajes)
  // Pasamos el historial al modelo para que tenga contexto de la charla anterior.
  const historyResult = await query<{ role: string; content: string }>(
    `SELECT role, content
     FROM messages
     WHERE conversation_id = $1
       AND role IN ('user', 'assistant')
     ORDER BY created_at DESC
     LIMIT 20`,
    [input.conversationId]
  );

  // Los mensajes vienen en orden DESC del DB, los invertimos para que vayan ASC
  const history: ChatMessage[] = historyResult.rows
    .reverse()
    .map(m => ({ role: m.role as 'user' | 'assistant', content: m.content }));

  // 3. Agregar el mensaje nuevo del usuario al historial
  history.push({ role: 'user', content: input.userMessage });

  // 4. Llamar a Claude con el system prompt del negocio y el historial
  const result = await callClaude({
    systemPrompt: buildSystemPrompt(profile),
    messages:     history,
  });

  // 5. Guardar la respuesta del agente en la tabla messages
  await createMessage(input.tenantId, input.conversationId, {
    role:       'assistant',
    content:    result.content,
    agent_type: 'secretary',
  });

  // 6. Guardar log en ai_logs para monitoreo de costos y debugging
  await query(
    `INSERT INTO ai_logs (tenant_id, agent_type, channel, input, output, tokens_used, latency_ms)
     VALUES ($1, 'secretary', 'api', $2, $3, $4, $5)`,
    [input.tenantId, input.userMessage, result.content, result.tokensUsed, result.latencyMs]
  );

  return {
    response:   result.content,
    tokensUsed: result.tokensUsed,
    latencyMs:  result.latencyMs,
  };
}
