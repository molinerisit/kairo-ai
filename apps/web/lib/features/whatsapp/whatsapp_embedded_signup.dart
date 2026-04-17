import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'whatsapp_connect_service.dart';
import '../../shared/theme/app_theme.dart';

@JS('kairoLoginMeta')
external JSPromise<JSObject> _loginMeta();

@JS('window.open')
external void _openUrl(JSString url, JSString target);

// ── ESTADOS DEL FLUJO ─────────────────────────────────────────────────────────

enum _Step { idle, logging, picking, connecting, done, noWaba }

class WhatsAppConnectSection extends StatefulWidget {
  const WhatsAppConnectSection({super.key});

  @override
  State<WhatsAppConnectSection> createState() => _WhatsAppConnectSectionState();
}

class _WhatsAppConnectSectionState extends State<WhatsAppConnectSection> {
  WhatsAppConnection?       _connection;
  List<PhoneNumberOption>   _options     = [];
  PhoneNumberOption?        _selected;
  String?                   _sessionId;
  _Step                     _step        = _Step.idle;
  bool                      _loading     = true;
  String?                   _error;

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

  // Paso 1: login con Meta → obtener code → backend intercambia por token
  Future<void> _startLogin() async {
    setState(() { _step = _Step.logging; _error = null; });
    try {
      final result      = await _loginMeta().toDart;
      final map         = result.dartify() as Map<Object?, Object?>?;
      final code        = map?['code']         as String?;
      final accessToken = map?['access_token'] as String?;

      if (code == null && accessToken == null) throw Exception('Meta no devolvió credencial de autorización');

      // Paso 2: backend resuelve token y fetchea WABAs y números
      final (:accounts, :sessionId) = await WhatsAppConnectService.getAccounts(
        code: code,
        accessToken: accessToken,
      );
      final options = accounts;

      if (options.isEmpty) {
        setState(() { _step = _Step.noWaba; });
        return;
      }

      setState(() {
        _sessionId = sessionId;
        _options   = options;
        _selected  = options.length == 1 ? options.first : null;
        _step      = _Step.picking;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _step  = _Step.idle;
      });
    }
  }

  // Paso 3: confirmar el número elegido
  Future<void> _confirmConnect() async {
    if (_selected == null || _sessionId == null) return;
    setState(() { _step = _Step.connecting; _error = null; });
    try {
      final conn = await WhatsAppConnectService.connect(
        sessionId:     _sessionId!,
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
          _SectionHeader(isActive: _connection?.isActive ?? false),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 20),

          if (_loading)
            const Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
          else if (_connection != null && _connection!.isActive && _step != _Step.picking)
            _ConnectedView(connection: _connection!, onDisconnect: _disconnect)
          else if (_step == _Step.noWaba)
            _NoWabaView(
              onRetry: () => setState(() { _step = _Step.idle; _error = null; }),
            )
          else if (_step == _Step.picking)
            _PickerView(
              options:   _options,
              selected:  _selected,
              loading:   _step == _Step.connecting,
              onSelect:  (o) => setState(() => _selected = o),
              onConfirm: _step == _Step.connecting ? null : _confirmConnect,
              onCancel:  () => setState(() { _step = _Step.idle; _options = []; _sessionId = null; }),
            )
          else
            _DisconnectedView(
              loading: _step == _Step.logging,
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
}

// ── HEADER ─────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final bool isActive;
  const _SectionHeader({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final statusColor = isActive ? const Color(0xFF25D366) : AppColors.textSecondary;

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
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            isActive ? 'Conectado' : 'Sin conectar',
            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ── VISTA: DESCONECTADO ────────────────────────────────────────────────────────

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

// ── VISTA: PICKER DE NÚMEROS ───────────────────────────────────────────────────

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
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.background,
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

// ── VISTA: CONECTADO ───────────────────────────────────────────────────────────

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

// ── VISTA: SIN WABA ────────────────────────────────────────────────────────────

class _NoWabaView extends StatelessWidget {
  final VoidCallback onRetry;
  const _NoWabaView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Text('No encontramos números en tu cuenta',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            SizedBox(height: 10),
            Text(
              'Para usar WhatsApp Business en AXIIA necesitás:\n'
              '1. Una cuenta de Meta Business Manager\n'
              '2. Un WhatsApp Business Account (WABA)\n'
              '3. Un número de teléfono registrado en ese WABA',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text('Seguí estos pasos para configurarlo:',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      _StepItem(number: '1', text: 'Creá tu cuenta en Meta Business Manager'),
      _StepItem(number: '2', text: 'Dentro de Business Manager, creá un WhatsApp Business Account'),
      _StepItem(number: '3', text: 'Agregá y verificá tu número de teléfono'),
      _StepItem(number: '4', text: 'Volvé acá y hacé clic en "Reintentar"'),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _launchUrl('https://business.facebook.com'),
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('Abrir Business Manager', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
            child: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ]),
    ],
  );

  void _launchUrl(String url) {
    _openUrl(url.toJS, '_blank'.toJS);
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4))),
      ],
    ),
  );
}

// ── ERROR ──────────────────────────────────────────────────────────────────────

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
