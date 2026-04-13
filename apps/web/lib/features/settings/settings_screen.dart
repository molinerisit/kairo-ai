import 'package:flutter/material.dart';
import 'settings_service.dart';
import '../../shared/api/api_client.dart';
import '../../shared/theme/app_theme.dart';

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
                      _WhatsAppSection(profile: _profile!, onSaved: _load),
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

// ── SECCIÓN WHATSAPP ───────────────────────────────────────────────────────────

class _WhatsAppSection extends StatefulWidget {
  final BusinessProfile profile;
  final VoidCallback onSaved;
  const _WhatsAppSection({required this.profile, required this.onSaved});

  @override
  State<_WhatsAppSection> createState() => _WhatsAppSectionState();
}

class _WhatsAppSectionState extends State<_WhatsAppSection> {
  late final TextEditingController _phoneIdCtrl;
  bool    _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneIdCtrl = TextEditingController(text: widget.profile.whatsapp ?? '');
  }

  @override
  void dispose() {
    _phoneIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await SettingsService.updateProfile({'whatsapp': _phoneIdCtrl.text.trim()});
      widget.onSaved();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = (widget.profile.whatsapp ?? '').isNotEmpty;
    return _SectionCard(
      title:    'WhatsApp Business',
      subtitle: 'Conectá tu número mediante Meta Cloud API',
      icon:     Icons.chat_outlined,
      onSave:   _save,
      saving:   _saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Estado ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (connected ? AppColors.success : AppColors.textSecondary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (connected ? AppColors.success : AppColors.textSecondary).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  connected ? Icons.check_circle_outline : Icons.phone_disabled_outlined,
                  size: 14,
                  color: connected ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  connected ? 'Configurado' : 'Sin configurar',
                  style: TextStyle(
                    color: connected ? AppColors.success : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Campo Phone Number ID ────────────────────────────────
          _Field(
            controller: _phoneIdCtrl,
            label: 'Phone Number ID',
            hint:  'ej: 123456789012345',
          ),
          const SizedBox(height: 12),

          // ── Instrucciones ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cómo obtener el Phone Number ID:',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text(
                  '1. Abrí Meta for Developers → Tu app\n'
                  '2. WhatsApp → Configuración de API\n'
                  '3. Copiá el "ID de número de teléfono"\n'
                  '4. Configurá el webhook con la URL de tu kairo y el verify token',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),

          // ── Error ────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
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
