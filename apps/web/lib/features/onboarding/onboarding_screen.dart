import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/settings/settings_service.dart';
import '../../shared/theme/app_theme.dart';

// OnboardingScreen — pantalla de configuración inicial para nuevos tenants.
//
// Se muestra una sola vez, justo después del registro.
// Pide lo mínimo para que el agente IA sea útil desde el día 1:
//   - Descripción breve del negocio (qué hace, para quién)
//   - Tono de comunicación del agente
//   - Número de WhatsApp (opcional)
//
// El nombre del negocio ya fue capturado en el registro.
// Horarios, servicios y FAQs se pueden completar en Configuración.

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _descCtrl     = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  // Tono seleccionado — el usuario elige entre opciones predefinidas.
  // El valor se envía directamente al system prompt del agente.
  String _selectedTone = 'amable y profesional';

  bool    _saving = false;
  String? _error;

  static const _tones = [
    (value: 'amable y profesional',  label: 'Amable',      icon: Icons.favorite_outline),
    (value: 'formal y corporativo',  label: 'Formal',       icon: Icons.business_center_outlined),
    (value: 'divertido y cercano',   label: 'Divertido',    icon: Icons.emoji_emotions_outlined),
    (value: 'neutro y directo',      label: 'Directo',      icon: Icons.bolt_outlined),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _saving = true; _error = null; });

    try {
      final body = <String, dynamic>{
        'tone':        _selectedTone,
        'description': _descCtrl.text.trim(),
      };
      if (_whatsappCtrl.text.trim().isNotEmpty) {
        body['whatsapp'] = _whatsappCtrl.text.trim();
      }

      await SettingsService.updateProfile(body);

      if (!mounted) return;
      context.read<AuthProvider>().clearJustRegistered();
      context.go('/dashboard');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skip() {
    context.read<AuthProvider>().clearJustRegistered();
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                const Text(
                  'Kairo AI',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 3,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Configurá tu asistente',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Solo toma 1 minuto. Esto le da contexto a tu agente para responder como parte de tu equipo.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 40),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Descripción ────────────────────────────────────────
                      _Label('¿Qué hace tu negocio?'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Ej: Peluquería unisex en Buenos Aires. '
                              'Ofrecemos cortes, coloración y tratamientos capilares. '
                              'Atendemos con turno previo de lunes a sábado.',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Contale a tu agente qué hace el negocio';
                          }
                          if (v.trim().length < 20) {
                            return 'Sé un poco más descriptivo (mínimo 20 caracteres)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Tono ───────────────────────────────────────────────
                      _Label('¿Cómo debe sonar tu asistente?'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _tones.map((t) {
                          final selected = _selectedTone == t.value;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTone = t.value),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    t.icon,
                                    size: 16,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // ── WhatsApp ───────────────────────────────────────────
                      _Label('Número de WhatsApp Business (opcional)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _whatsappCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Ej: 541112345678',
                          prefixIcon: Icon(Icons.phone_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Número completo sin + ni espacios. Podés agregarlo después en Configuración.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Error ──────────────────────────────────────────────
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13),
                          ),
                        ),

                      // ── Botones ────────────────────────────────────────────
                      Row(
                        children: [
                          // Saltar (sin guardar)
                          TextButton(
                            onPressed: _saving ? null : _skip,
                            child: const Text(
                              'Saltar por ahora',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const Spacer(),
                          // Empezar
                          ElevatedButton(
                            onPressed: _saving ? null : _finish,
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Empezar →'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// _Label — título de sección dentro del form
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
