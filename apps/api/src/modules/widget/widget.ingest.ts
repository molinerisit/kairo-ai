import { callOpenAI } from '../../shared/ai/openai.client';
import { query } from '../../shared/db/pool';

// ── INGESTA DEL SITIO DEL CLIENTE ─────────────────────────────────────────────
// Scrapea el sitio/ecommerce del cliente y, con la IA, genera la base de
// conocimiento + saludo + quick-replies que autoconfiguran al widget Kairos.

export interface IngestResult {
  source_url:    string;
  pages_crawled: number;
  knowledge:     string;
  greeting:      string;
  quick_replies: string[];
}

const MAX_PAGES      = 5;
const MAX_TOTAL_CHARS = 12000;
const FETCH_TIMEOUT  = 10000;

// Palabras que indican páginas valiosas para el asistente.
const PRIORITY_HINTS = [
  'sobre', 'nosotros', 'about', 'product', 'producto', 'tienda', 'shop', 'catalogo', 'catálogo',
  'servicio', 'service', 'precio', 'pricing', 'plan', 'contact', 'contacto', 'faq', 'preguntas',
  'envio', 'envío', 'pago',
];

// ── Crawl ─────────────────────────────────────────────────────────────────────

interface CrawledPage { url: string; title: string; text: string; }

export async function crawlSite(startUrl: string): Promise<CrawledPage[]> {
  const root = normalizeUrl(startUrl);
  const origin = new URL(root).origin;

  const home = await fetchPage(root);
  if (!home) throw { statusCode: 422, message: 'No se pudo acceder al sitio. Verificá la URL.' };

  const pages: CrawledPage[] = [home];
  const visited = new Set<string>([stripHash(root)]);

  // Elegir links internos prioritarios desde la home.
  const candidates = extractLinks(home.rawHtml, origin)
    .filter(u => !visited.has(stripHash(u)))
    .sort((a, b) => linkScore(b) - linkScore(a))
    .slice(0, MAX_PAGES - 1);

  for (const url of candidates) {
    if (pages.length >= MAX_PAGES) break;
    const key = stripHash(url);
    if (visited.has(key)) continue;
    visited.add(key);
    const page = await fetchPage(url);
    if (page && page.text.length > 80) pages.push(page);
  }

  return pages.map(({ url, title, text }) => ({ url, title, text }));
}

interface RawPage extends CrawledPage { rawHtml: string; }

async function fetchPage(url: string): Promise<RawPage | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT);
  try {
    const res = await fetch(url, {
      signal: controller.signal,
      redirect: 'follow',
      headers: { 'User-Agent': 'KairosBot/1.0 (+https://getaxiia.com)' },
    });
    if (!res.ok) return null;
    const ctype = res.headers.get('content-type') ?? '';
    if (!ctype.includes('text/html')) return null;
    const rawHtml = (await res.text()).slice(0, 400_000);
    return { url, title: extractTitle(rawHtml), text: htmlToText(rawHtml), rawHtml };
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

// ── Generación con IA ─────────────────────────────────────────────────────────

export async function ingestSite(tenantId: string, url: string): Promise<IngestResult> {
  const pages = await crawlSite(url);

  let combined = pages
    .map(p => `## ${p.title || p.url}\n(${p.url})\n${p.text}`)
    .join('\n\n');
  if (combined.length > MAX_TOTAL_CHARS) combined = combined.slice(0, MAX_TOTAL_CHARS);

  const systemPrompt =
`Sos un asistente que configura un chatbot de atención al cliente analizando el sitio web de un negocio.
A partir del contenido scrapeado, generás la base de conocimiento para que el bot responda como si trabajara ahí.
Respondé ÚNICAMENTE con un objeto JSON válido (sin markdown, sin texto extra) con esta forma exacta:
{
  "knowledge": "texto markdown conciso con: qué es el negocio, productos/servicios principales (con precios si aparecen), datos de contacto/envíos/pagos y FAQs. Máximo ~350 palabras. No inventes datos que no estén en el contenido.",
  "greeting": "saludo inicial breve y cálido del bot, en el idioma del sitio, mencionando al negocio (máx 120 caracteres)",
  "quick_replies": ["3 a 4 preguntas cortas que un visitante haría, en el idioma del sitio, máx 40 caracteres cada una"]
}`;

  const userPrompt =
`URL del sitio: ${url}

Contenido scrapeado de hasta ${pages.length} páginas:
"""
${combined}
"""`;

  const result = await callOpenAI({
    systemPrompt,
    messages: [{ role: 'user', content: userPrompt }],
    maxTokens: 900,
  });

  const parsed = parseJsonLoose(result.content);

  const knowledge = String(parsed.knowledge ?? '').trim();
  const greeting  = String(parsed.greeting ?? '').trim().slice(0, 200);
  const quick     = Array.isArray(parsed.quick_replies)
    ? parsed.quick_replies.map((q: unknown) => String(q).trim()).filter(Boolean).slice(0, 4)
    : [];

  if (!knowledge) throw { statusCode: 422, message: 'No se pudo generar conocimiento del sitio.' };

  // Guardar en la config del tenant.
  await query(
    `UPDATE widget_configs
     SET source_url = $2, knowledge = $3,
         greeting = COALESCE(NULLIF($4, ''), greeting),
         quick_replies = $5::jsonb,
         updated_at = now()
     WHERE tenant_id = $1`,
    [tenantId, normalizeUrl(url), knowledge, greeting, JSON.stringify(quick)]
  );

  return {
    source_url:    normalizeUrl(url),
    pages_crawled: pages.length,
    knowledge,
    greeting,
    quick_replies: quick,
  };
}

// ── Helpers de parsing HTML / texto ───────────────────────────────────────────

function normalizeUrl(u: string): string {
  let s = u.trim();
  if (!/^https?:\/\//i.test(s)) s = 'https://' + s;
  return s;
}

function stripHash(u: string): string {
  try { const x = new URL(u); x.hash = ''; return x.href; } catch { return u; }
}

function extractTitle(html: string): string {
  const m = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  return m ? decodeEntities(m[1]).trim().slice(0, 120) : '';
}

function htmlToText(html: string): string {
  return decodeEntities(
    html
      .replace(/<(script|style|noscript|svg|template)[\s\S]*?<\/\1>/gi, ' ')
      .replace(/<!--[\s\S]*?-->/g, ' ')
      .replace(/<\/(p|div|li|h[1-6]|br|tr|section|article)>/gi, '\n')
      .replace(/<[^>]+>/g, ' ')
  )
    .replace(/[ \t\f\v]+/g, ' ')
    .replace(/\n\s*\n\s*\n+/g, '\n\n')
    .trim();
}

function extractLinks(html: string, origin: string): string[] {
  const links: string[] = [];
  const re = /<a\b[^>]*\bhref\s*=\s*["']([^"'#]+)["']/gi;
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) !== null) {
    try {
      const abs = new URL(m[1], origin).href;
      if (abs.startsWith(origin)) links.push(abs);
    } catch { /* link inválido, ignorar */ }
  }
  // Únicos, preservando orden.
  return Array.from(new Set(links));
}

function linkScore(url: string): number {
  const low = url.toLowerCase();
  let score = 0;
  for (const hint of PRIORITY_HINTS) if (low.includes(hint)) score += 2;
  // Penalizar URLs muy profundas (probablemente menos representativas).
  score -= (low.split('/').length - 3) * 0.2;
  return score;
}

function decodeEntities(s: string): string {
  return s
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(parseInt(n, 10)));
}

// Parsea JSON aunque el modelo lo envuelva en ```json o agregue texto alrededor.
function parseJsonLoose(raw: string): Record<string, unknown> {
  const cleaned = raw.replace(/```json/gi, '').replace(/```/g, '').trim();
  try { return JSON.parse(cleaned); } catch { /* intentar extraer el primer objeto */ }
  const start = cleaned.indexOf('{');
  const end   = cleaned.lastIndexOf('}');
  if (start !== -1 && end > start) {
    try { return JSON.parse(cleaned.slice(start, end + 1)); } catch { /* noop */ }
  }
  return {};
}
