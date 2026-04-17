import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'whatsapp_connect_service.dart';
import '../../shared/theme/app_theme.dart';

@JS('kairoStartWhatsAppSignup')
external JSPromise<JSObject> _startWhatsAppSignup();

@JS('window.open')
external void _openUrl(JSString url, JSString target);

// ── ESTADOS DEL FLUJO ─────────────────────────────────────────────────────────

enum _Step { idle, logging, noNumbers, picking, connecting, done }

// ── WIDGET PRINCIPAL ──────────────────────────────────────────────────────────

class WhatsAppConnectSection extends StatefulWidget {
  const WhatsAppConnectSection({super.key});

  @override
  State<WhatsAppConnectSection> createState() => _WhatsAppConnectSectionState();
}

class _WhatsAppConnectSectionState extends State<WhatsAppConnectSection> {
  WhatsAppConnection?     _connection;
  List<PhoneNumberOption> _options  = [];
  PhoneNumberOption?      _selected;
  String?                 _code;
  _Step                   _step     = _Step.idle;
  bool                    _loading  = true;
  String?                 _error;

  @override
  void initState() {
    super.initState();
    _loadConnection();
  }

  Future<void> _loadConnection() async {
    setState(() { _loading = true; _error = null; });
    try {
      final conn = await WhatsAppConnectService.getConnection();
      setState(() { _connection = conn; _step = _Step.idle; });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // Paso 1: login con Meta → code → auto-fetch WABAs + números
  Future<void> _startLogin() async {
    setState(() { _step = _Step.logging; _error = null; });
    try {
      final result = await _startWhatsAppSignup().toDart;
      final map    = result.dartify() as Map<Object?, Object?>?;
      final code   = map?['code'] as String?;
      if (code == null) throw Exception('Meta no devolvió el code de autorización');

      final accounts = await WhatsAppConnectService.getAccounts(code: code);

      if (accounts.isEmpty) {
        // Meta conectada, pero sin números — mostrar onboarding guiado
        setState(() { _code = code; _step = _Step.noNumbers; });
        return;
      }

      setState(() {
        _code     = code;
        _options  = accounts;
        _selected = accounts.length == 1 ? accounts.first : null;
        _step     = _Step.picking;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _step  = _Step.idle;
      });
    }
  }

  // Paso 2: confirmar el número elegido
  Future<void> _confirmConnect() async {
    if (_selected == null || _code == null) return;
    setState(() { _step = _Step.connecting; _error = null; });
    try {
      final conn = await WhatsAppConnectService.connect(
        code:          _code!,
        wabaId:        _selected!.wabaId,
        phoneNumberId: _selected!.phoneNumberId,
      );
      setState(() { _connection = conn; _step = _Step.done; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _step  = _Step.picking;
      });
    }
  }

  Future<void> _disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Desconectar WhatsApp',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text('Tu número dejará de recibir mensajes en AXIIA.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Desconectar', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    await WhatsAppConnectService.disconnect();
    await _loadConnection();
  }

  _HeaderStatus get _headerStatus {
    if (_connection?.isActive == true && _step != _Step.picking) return _HeaderStatus.connected;
    if (_step == _Step.noNumbers) return _HeaderStatus.inProgress;
    return _HeaderStatus.disconnected;
  }

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
          _SectionHeader(status: _headerStatus),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 20),

          if (_loading)
            const Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
          else if (_connection != null && _connection!.isActive && _step != _Step.picking)
            _ConnectedView(connection: _connection!, onDisconnect: _disconnect)
          else if (_step == _Step.noNumbers)
            _NoNumbersView(onRetry: _startLogin, onOpenManager: _openWhatsAppManager)
          else if (_step == _Step.picking || _step == _Step.connecting)
            _PickerView(
              options:   _options,
              selected:  _selected,
              loading:   _step == _Step.connecting,
              onSelect:  (o) => setState(() => _selected = o),
              onConfirm: _step == _Step.connecting ? null : _confirmConnect,
              onCancel:  () => setState(() { _step = _Step.idle; _options = []; _code = null; }),
            )
          else
            _DisconnectedView(
              loading:   _step == _Step.logging,
              onConnect: _step == _Step.logging ? null : _startLogin,
            ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorText(message: _error!),
          ],
        ],
      ),
    );
  }

  void _openWhatsAppManager() =>
      _openUrl('https://business.facebook.com/wa/manage/phone-numbers/'.toJS, '_blank'.toJS);
}

// ── HEADER ────────────────────────────────────────────────────────────────────

enum _HeaderStatus { connected, inProgress, disconnected }

class _SectionHeader extends StatelessWidget {
  final _HeaderStatus status;
  const _SectionHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      _HeaderStatus.connected    => (const Color(0xFF25D366), 'Conectado'),
      _HeaderStatus.inProgress   => (const Color(0xFFF59E0B), 'En configuración'),
      _HeaderStatus.disconnected => (AppColors.textSecondary, 'Sin conectar'),
    };

    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 18),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WhatsApp Business',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              Text('Conectá tu número en 2 minutos',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── VISTA: DESCONECTADO ───────────────────────────────────────────────────────

class _DisconnectedView extends StatelessWidget {
  final bool          loading;
  final VoidCallback? onConnect;
  const _DisconnectedView({required this.loading, required this.onConnect});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Conectá el número de WhatsApp de tu negocio. '
        'Iniciás sesión con Meta y elegís qué número usar.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onConnect,
          icon: loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.login, size: 16),
          label: Text(
            loading ? 'Conectando con Meta...' : 'Conectar WhatsApp',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1877F2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ],
  );
}

// ── VISTA: SIN NÚMEROS — ONBOARDING GUIADO ───────────────────────────────────

class _NoNumbersView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onOpenManager;
  const _NoNumbersView({required this.onRetry, required this.onOpenManager});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Checklist de progreso
      _OnboardingChecklist(
        items: const [
          (label: 'Cuenta Meta conectada',     done: true),
          (label: 'Número de WhatsApp agregado', done: false),
          (label: 'Automatización activa',       done: false),
        ],
      ),
      const SizedBox(height: 20),

      // Mensaje principal
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_android, color: Color(0xFFF59E0B), size: 15),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Todavía no tenés un número conectado',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 10),
            const Text(
              'Tu cuenta de Meta está conectada. El próximo paso es agregar '
              'un número de WhatsApp Business desde el panel de Meta.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // Instrucciones paso a paso
      const Text('¿Cómo agregarlo?',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      const _OnboardingStep(n: '1', text: 'Abrí el panel de WhatsApp Manager (botón abajo)'),
      const _OnboardingStep(n: '2', text: 'Seleccioná tu cuenta de WhatsApp Business'),
      const _OnboardingStep(n: '3', text: 'Tocá "Agregar número de teléfono"'),
      const _OnboardingStep(n: '4', text: 'Completá la verificación del número'),
      const _OnboardingStep(n: '5', text: 'Volvé acá y tocá "Ya lo configuré"'),
      const SizedBox(height: 24),

      // Botones
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onOpenManager,
          icon: const Icon(Icons.open_in_new, size: 15),
          label: const Text('Abrir WhatsApp Manager',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 15),
          label: const Text('Ya lo configuré, volver a intentar',
              style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ],
  );
}

// ── CHECKLIST DE PROGRESO ─────────────────────────────────────────────────────

typedef _CheckItem = ({String label, bool done});

class _OnboardingChecklist extends StatelessWidget {
  final List<_CheckItem> items;
  const _OnboardingChecklist({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: items.map((item) {
        final color = item.done ? const Color(0xFF25D366) : AppColors.textSecondary;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                item.done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(item.label,
                  style: TextStyle(
                    color: item.done ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: item.done ? FontWeight.w600 : FontWeight.normal,
                  )),
              if (!item.done) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Pendiente',
                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    ),
  );
}

// ── PASO DE INSTRUCCIÓN ───────────────────────────────────────────────────────

class _OnboardingStep extends StatelessWidget {
  final String n;
  final String text;
  const _OnboardingStep({required this.n, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(n,
                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(text,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          ),
        ),
      ],
    ),
  );
}

// ── VISTA: PICKER DE NÚMEROS ──────────────────────────────────────────────────

class _PickerView extends StatelessWidget {
  final List<PhoneNumberOption> options;
  final PhoneNumberOption?      selected;
  final bool                    loading;
  final ValueChanged<PhoneNumberOption> onSelect;
  final VoidCallback?           onConfirm;
  final VoidCallback            onCancel;

  const _PickerView({
    required this.options,
    required this.selected,
    required this.loading,
    required this.onSelect,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Elegí el número que querés conectar:',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),

      ...options.map((opt) => _PhoneOption(
        option:     opt,
        isSelected: selected?.phoneNumberId == opt.phoneNumberId,
        onTap:      () => onSelect(opt),
      )),

      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: loading ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: (selected == null || loading) ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: loading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ],
  );
}

class _PhoneOption extends StatelessWidget {
  final PhoneNumberOption option;
  final bool              isSelected;
  final VoidCallback      onTap;

  const _PhoneOption({required this.option, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.displayPhone,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(option.wabaName,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ── VISTA: CONECTADO ──────────────────────────────────────────────────────────

class _ConnectedView extends StatelessWidget {
  final WhatsAppConnection connection;
  final VoidCallback        onDisconnect;
  const _ConnectedView({required this.connection, required this.onDisconnect});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF25D366), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.phoneNumber ?? connection.phoneNumberId ?? 'Número conectado',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  if (connection.wabaId != null)
                    Text('WABA: ${connection.wabaId}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: onDisconnect,
        icon: const Icon(Icons.link_off, size: 16, color: AppColors.danger),
        label: const Text('Desconectar número',
            style: TextStyle(color: AppColors.danger, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    ],
  );
}

// ── ERROR ─────────────────────────────────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: const TextStyle(color: AppColors.danger, fontSize: 12, height: 1.4))),
      ],
    ),
  );
}
