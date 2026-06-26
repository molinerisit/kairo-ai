import '../../shared/api/api_client.dart';

// ── MODELOS ────────────────────────────────────────────────────────────────────

class WidgetEmbed {
  final String siteKey;
  final String snippet;

  WidgetEmbed({required this.siteKey, required this.snippet});

  factory WidgetEmbed.fromJson(Map<String, dynamic> j) => WidgetEmbed(
        siteKey: j['site_key'] as String? ?? '',
        snippet: j['snippet'] as String? ?? '',
      );
}

class WidgetIngestResult {
  final String sourceUrl;
  final int pagesCrawled;
  final String greeting;
  final List<String> quickReplies;

  WidgetIngestResult({
    required this.sourceUrl,
    required this.pagesCrawled,
    required this.greeting,
    required this.quickReplies,
  });

  factory WidgetIngestResult.fromJson(Map<String, dynamic> j) => WidgetIngestResult(
        sourceUrl:    j['source_url'] as String? ?? '',
        pagesCrawled: (j['pages_crawled'] as num?)?.toInt() ?? 0,
        greeting:     j['greeting'] as String? ?? '',
        quickReplies: (j['quick_replies'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

// ── SERVICIO ───────────────────────────────────────────────────────────────────

class WidgetSettingsService {
  // Provisiona (si hace falta) y devuelve la site_key + snippet del widget.
  static Future<WidgetEmbed> getEmbed() async {
    final data = await ApiClient.get('/api/widget/embed') as Map<String, dynamic>;
    return WidgetEmbed.fromJson(data);
  }

  // Scrapea el sitio del cliente y autoconfigura el widget.
  static Future<WidgetIngestResult> ingest(String url) async {
    final data = await ApiClient.post('/api/widget/ingest', body: {'url': url}) as Map<String, dynamic>;
    return WidgetIngestResult.fromJson(data);
  }
}
