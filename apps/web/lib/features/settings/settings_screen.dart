import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';
import 'widget_settings_service.dart';
import '../../shared/theme/app_theme.dart';
import '../whatsapp/whatsapp_embedded_signup.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BusinessProfile? _profile;
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await SettingsService.getProfile();
      setState(() => _profile = p);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Text('Configuración', style: Theme.of(context).textTheme.headlineLarge),
                const Spacer(),
                IconButton(
                  onPressed: _loading ? null : _load,
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : const Icon(Icons.refresh_outlined, size: 18),
                  color: AppColors.textSecondary,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const Text('Perfil del negocio y configuración del agente',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),

            // ── Contenido ────────────────────────────────────────────────────
            if (_error != null)
              _ErrorBanner(message: _error!)
            else if (_loading && _profile == null)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_profile != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ProfileSection(profile: _profile!, onSaved: _load),
                      const SizedBox(height: 24),
                      _AgentSection(profile: _profile!, onSaved: _load),
                      const SizedBox(height: 24),
                      const WhatsAppConnectSection(),
                      const SizedBox(height: 24),
                      const _WidgetSection(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── BANNER DE ERROR ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
      ],
    ),
  );
}

// ── SECCIÓN BASE ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final VoidCallback? onSave;
  final bool saving;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.onSave,
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 20),
          child,
          if (onSave != null) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: saving ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: saving
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── PERFIL DEL NEGOCIO ─────────────────────────────────────────────────────────

class _ProfileSection extends StatefulWidget {
  final BusinessProfile profile;
  final VoidCallback onSaved;
  const _ProfileSection({required this.profile, required this.onSaved});

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.profile.name);
    _descCtrl    = TextEditingController(text: widget.profile.description ?? '');
    _addressCtrl = TextEditingController(text: widget.profile.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await SettingsService.updateProfile({
        'name':        _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'address':     _addressCtrl.text.trim(),
      });
      widget.onSaved();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title:    'Perfil del negocio',
      subtitle: 'Nombre, descripción y dirección',
      icon:     Icons.storefront_outlined,
      onSave:   _save,
      saving:   _saving,
      child: Column(
        children: [
          _Field(controller: _nameCtrl,    label: 'Nombre del negocio'),
          const SizedBox(height: 12),
          _Field(controller: _descCtrl,    label: 'Descripción', maxLines: 3),
          const SizedBox(height: 12),
          _Field(controller: _addressCtrl, label: 'Dirección (opcional)'),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

// ── CONFIGURACIÓN DEL AGENTE ───────────────────────────────────────────────────

class _AgentSection extends StatefulWidget {
  final BusinessProfile profile;
  final VoidCallback onSaved;
  const _AgentSection({required this.profile, required this.onSaved});

  @override
  State<_AgentSection> createState() => _AgentSectionState();
}

class _AgentSectionState extends State<_AgentSection> {
  late final TextEditingController _toneCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _servicesCtrl;
  late final TextEditingController _faqsCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _toneCtrl    = TextEditingController(text: widget.profile.tone ?? '');
    // Horarios: "lunes: 9:00-18:00\nmartes: 9:00-18:00"
    _hoursCtrl   = TextEditingController(
      text: widget.profile.hours.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
    );
    // Servicios: "Servicio 1 - $2500\nServicio 2"
    _servicesCtrl = TextEditingController(
      text: widget.profile.services.map((s) => s.price != null ? '${s.name} - \$${s.price!.toStringAsFixed(0)}' : s.name).join('\n'),
    );
    // FAQs: "¿Pregunta?\nRespuesta\n---\n¿Pregunta 2?\nRespuesta 2"
    _faqsCtrl = TextEditingController(
      text: widget.profile.faqs.map((f) => '${f.q}\n${f.a}').join('\n---\n'),
    );
  }

  @override
  void dispose() {
    _toneCtrl.dispose();
    _hoursCtrl.dispose();
    _servicesCtrl.dispose();
    _faqsCtrl.dispose();
    super.dispose();
  }

  // Parsea "lunes: 9:00-18:00\nmartes: cerrado" → {"lunes": "9:00-18:00", ...}
  Map<String, String> _parseHours(String text) {
    final result = <String, String>{};
    for (final line in text.split('\n')) {
      final idx = line.indexOf(':');
      if (idx < 0) continue;
      final key = line.substring(0, idx).trim();
      final val = line.substring(idx + 1).trim();
      if (key.isNotEmpty && val.isNotEmpty) result[key] = val;
    }
    return result;
  }

  // Parsea "Corte - $2500\nTinte" → [{name: "Corte", price: 2500}, {name: "Tinte"}]
  List<Map<String, dynamic>> _parseServices(String text) {
    return text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) {
          final parts = l.split(RegExp(r'\s*-\s*\$'));
          final name  = parts[0].trim();
          final price = parts.length > 1 ? double.tryParse(parts[1].replaceAll(',', '')) : null;
          return <String, dynamic>{'name': name, 'price': price}..removeWhere((_, v) => v == null);
        })
        .toList();
  }

  // Parsea "¿Pregunta?\nRespuesta\n---\n¿Pregunta 2?\nRespuesta 2"
  List<Map<String, dynamic>> _parseFaqs(String text) {
    return text.split('---')
        .map((block) {
          final lines = block.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
          if (lines.length < 2) return null;
          return <String, dynamic>{'q': lines[0], 'a': lines.sublist(1).join(' ')};
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await SettingsService.updateProfile({
        'tone':     _toneCtrl.text.trim(),
        'hours':    _parseHours(_hoursCtrl.text),
        'services': _parseServices(_servicesCtrl.text),
        'faqs':     _parseFaqs(_faqsCtrl.text),
      });
      widget.onSaved();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title:    'Configuración del agente',
      subtitle: 'Tono, horarios, servicios y preguntas frecuentes',
      icon:     Icons.smart_toy_outlined,
      onSave:   _save,
      saving:   _saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            controller: _toneCtrl,
            label: 'Tono del agente',
            hint: 'ej: amable y profesional, formal, informal',
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _hoursCtrl,
            label: 'Horarios (un día por línea)',
            hint: 'lunes: 9:00-18:00\nsábado: 9:00-13:00\ndomingo: cerrado',
            maxLines: 5,
            monospace: true,
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _servicesCtrl,
            label: 'Servicios (uno por línea, precio opcional)',
            hint: 'Corte de pelo - \$2500\nTinte\nMechas - \$8000',
            maxLines: 5,
            monospace: true,
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _faqsCtrl,
            label: 'Preguntas frecuentes (separadas por ---)',
            hint: '¿Aceptan tarjeta?\nSí, débito y crédito\n---\n¿Hacen delivery?\nNo, solo en local',
            maxLines: 8,
            monospace: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}


// ── WIDGET WEB (KAIROS) ─────────────────────────────────────────────────────────

class _WidgetSection extends StatefulWidget {
  const _WidgetSection();

  @override
  State<_WidgetSection> createState() => _WidgetSectionState();
}

class _WidgetSectionState extends State<_WidgetSection> {
  final _urlCtrl = TextEditingController();
  WidgetEmbed? _embed;
  bool _loadingEmbed = true;
  String? _embedError;
  bool _ingesting = false;
  String? _ingestError;
  WidgetIngestResult? _result;

  @override
  void initState() {
    super.initState();
    _loadEmbed();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmbed() async {
    setState(() { _loadingEmbed = true; _embedError = null; });
    try {
      final e = await WidgetSettingsService.getEmbed();
      setState(() => _embed = e);
    } catch (e) {
      setState(() => _embedError = e.toString());
    } finally {
      setState(() => _loadingEmbed = false);
    }
  }

  Future<void> _ingest() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _ingesting = true; _ingestError = null; _result = null; });
    try {
      final r = await WidgetSettingsService.ingest(url);
      setState(() => _result = r);
    } catch (e) {
      setState(() => _ingestError = e.toString());
    } finally {
      setState(() => _ingesting = false);
    }
  }

  void _copySnippet() {
    if (_embed == null) return;
    Clipboard.setData(ClipboardData(text: _embed!.snippet));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Snippet copiado al portapapeles'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title:    'Widget web (Kairos)',
      subtitle: 'Instalá el asistente en tu sitio y autoconfiguralo',
      icon:     Icons.public_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Snippet ──────────────────────────────────────────────────────
          const Text('1. Pegá este código en tu sitio web',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (_loadingEmbed)
            const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ))
          else if (_embedError != null)
            Text(_embedError!, style: const TextStyle(color: AppColors.danger, fontSize: 12))
          else if (_embed != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1D3F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    _embed!.snippet,
                    style: const TextStyle(color: Color(0xFFB7C7E6), fontSize: 12.5, height: 1.5, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _copySnippet,
                      icon: const Icon(Icons.copy_outlined, size: 15, color: AppColors.primary),
                      label: const Text('Copiar', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 24),

          // ── Autoconfiguración ────────────────────────────────────────────
          const Text('2. Autoconfigurá Kairos con el contenido de tu sitio',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'Analizamos tu web y generamos automáticamente el saludo, las respuestas y las opciones del asistente.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(controller: _urlCtrl, label: 'URL de tu sitio', hint: 'https://tunegocio.com'),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton.icon(
                  onPressed: _ingesting ? null : _ingest,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  icon: _ingesting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_fix_high_outlined, size: 16),
                  label: Text(_ingesting ? 'Analizando...' : 'Analizar mi sitio',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
          if (_ingestError != null) ...[
            const SizedBox(height: 8),
            Text(_ingestError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Text('Listo: analicé ${_result!.pagesCrawled} página(s) de tu sitio',
                          style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (_result!.greeting.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Saludo generado: "${_result!.greeting}"',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
                  ],
                  if (_result!.quickReplies.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: _result!.quickReplies.map((q) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(q, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── CAMPO DE TEXTO REUTILIZABLE ────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String  label;
  final String? hint;
  final int     maxLines;
  final bool    monospace;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines:   maxLines,
      style: TextStyle(
        color:      AppColors.textPrimary,
        fontSize:   13,
        fontFamily: monospace ? 'monospace' : null,
      ),
      decoration: InputDecoration(
        labelText:   label,
        hintText:    hint,
        hintStyle:   const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        hintMaxLines: maxLines,
      ),
    );
  }
}
