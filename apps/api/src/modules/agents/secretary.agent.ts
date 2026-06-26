import { callAI } from '../../shared/ai/ai.queue';
import type { ChatMessage } from '../../shared/ai/openai.client';
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

export interface PageAnchor {
  id:    string;   // id del elemento en la página del cliente
  label: string;   // título legible de la sección
}

export interface SecretaryInput {
  tenantId:       string;
  conversationId: string;
  userMessage:    string;   // el mensaje que acaba de llegar del cliente
  // Conocimiento extra del sitio web del cliente (widget). Si viene, se inyecta
  // al system prompt. Lo usa el canal web; en WhatsApp queda undefined.
  extraKnowledge?: string;
  // Secciones visibles de la página actual (widget). Si una aplica a la
  // respuesta, el agente la referencia y el widget ofrece "Llevame ahí".
  pageAnchors?:    PageAnchor[];
}

export interface SecretaryOutput {
  response:    string;    // la respuesta generada (sin tokens de control)
  tokensUsed:  number;
  latencyMs:   number;
  anchorId?:   string;    // sección de la página a la que llevar al visitante
}

// ── SYSTEM PROMPT ─────────────────────────────────────────────────────────────
// El system prompt define la personalidad y el conocimiento del agente.
// Se construye dinámicamente con los datos del perfil del negocio para que
// cada negocio tenga un asistente personalizado.

function buildSystemPrompt(profile: BusinessProfile, extraKnowledge?: string, anchors?: PageAnchor[]): string {
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

  // Secciones navegables de la página actual (anclas del widget web)
  const anchorsText = anchors && anchors.length > 0
    ? anchors.map(a => `  - ${a.id}: ${a.label}`).join('\n')
    : '';

  // Formateamos las FAQs
  const faqsText = profile.faqs.length > 0
    ? profile.faqs
        .map(f => `  P: ${f.q}\n  R: ${f.a}`)
        .join('\n\n')
    : '';

  return `Sos Kairos, el asistente virtual de ${desc}. Tu tono es ${tone}.

## Tu rol
Ayudás a los clientes respondiendo consultas, dando información del negocio y tomando turnos.
Sos servicial, conciso y usás el tono del negocio. Respondés en el mismo idioma que el cliente.
Nunca inventás información — si no sabés algo, pedís que se comuniquen directamente.
Te llamás Kairos. Si te preguntan tu nombre, decí que sos Kairos, el asistente del negocio.

## Información del negocio
**Dirección:** ${address}

**Horarios:**
${hoursText}

**Servicios:**
${servicesText}
${faqsText ? `\n## Preguntas frecuentes\n${faqsText}` : ''}
${extraKnowledge ? `\n## Conocimiento del sitio web\n${extraKnowledge}` : ''}
${anchorsText ? `\n## Navegación de la página\nEl visitante está viendo una página con estas secciones (id: título):\n${anchorsText}\n\nSi tu respuesta trata sobre una de estas secciones, terminá tu mensaje con una línea aparte exactamente así: [[anchor:ID]] (reemplazando ID por el id exacto de la sección). Si ninguna aplica, no agregues nada.` : ''}

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

  // 4. Llamar a GPT-4o-mini a través de la cola de IA
  const result = await callAI({
    systemPrompt: buildSystemPrompt(profile, input.extraKnowledge, input.pageAnchors),
    messages:     history,
  }, input.tenantId);

  // 4.b. Extraer el token de ancla [[anchor:ID]] y limpiar la respuesta.
  //      Validamos el id contra las anclas provistas para evitar alucinaciones.
  const anchorMatch = result.content.match(/\[\[anchor:([^\]]+)\]\]/i);
  const rawAnchorId = anchorMatch ? anchorMatch[1].trim() : undefined;
  const validIds    = new Set((input.pageAnchors ?? []).map(a => a.id));
  const anchorId    = rawAnchorId && validIds.has(rawAnchorId) ? rawAnchorId : undefined;
  const cleanContent = result.content.replace(/\[\[anchor:[^\]]+\]\]/gi, '').trim();

  // 5. Guardar la respuesta limpia del agente en la tabla messages
  await createMessage(input.tenantId, input.conversationId, {
    role:       'assistant',
    content:    cleanContent,
    agent_type: 'secretary',
  });

  // 6. Guardar log en ai_logs para monitoreo de costos y debugging
  await query(
    `INSERT INTO ai_logs (tenant_id, agent_type, channel, input, output, tokens_used, latency_ms)
     VALUES ($1, 'secretary', 'api', $2, $3, $4, $5)`,
    [input.tenantId, input.userMessage, cleanContent, result.tokensUsed, result.latencyMs]
  );

  return {
    response:   cleanContent,
    tokensUsed: result.tokensUsed,
    latencyMs:  result.latencyMs,
    anchorId,
  };
}
