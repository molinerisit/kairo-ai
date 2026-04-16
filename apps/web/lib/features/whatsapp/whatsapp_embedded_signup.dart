import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'whatsapp_connect_service.dart';
import '../../shared/theme/app_theme.dart';

// interop con la función kairoStartWhatsAppSignup() definida en index.html
@JS('kairoStartWhatsAppSignup')
external JSPromise<JSObject> _startSignup();

class WhatsAppConnectSection extends StatefulWidget {
  const WhatsAppConnectSection({super.key});

  @override
  State<WhatsAppConnectSection> createState() => _WhatsAppConnectSectionState();
}

class _WhatsAppConnectSectionState extends State<WhatsAppConnectSection> {
  WhatsAppConnection? _connection;
  bool    _loading    = true;
  bool    _connecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final conn = await WhatsAppConnectService.getConnection();
      setState(() => _connection = conn);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _startConnect() async {
    setState(() { _connecting = true; _error = null; });
    try {
      // 1. Abre el popup de Embedded Signup de Meta
      final result = await _startSignup().toDart;
      final jsObj  = result.dartify() as Map<Object?, Object?>?;

      if (jsObj == null) throw Exception('No se recibió respuesta del popup de Meta');

      final code           = jsObj['code']            as String?;
      final wabaId         = jsObj['waba_id']         as String?;
      final phoneNumberId  = jsObj['phone_number_id'] as String?;

      if (code == null) throw Exception('Meta no devolvió el código de autorización');

      // 2. Envía el code al backend para completar la vinculación
      final conn = await WhatsAppConnectService.connect(
        code: code,
        wabaId: wabaId,
        phoneNumberId: phoneNumberId,
      );

      setState(() => _connection = conn);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _connecting = false);
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Desconectar WhatsApp',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text('Tu número dejará de recibir mensajes en AXIIA.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desconectar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() { _connecting = true; _error = null; });
    try {
      await WhatsAppConnectService.disconnect();
      await _load();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _connecting = false);
    }
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
          // ── Header ────────────────────────────────────────────────
          Row(
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WhatsApp Business',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('Conectá tu número de WhatsApp',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 20),

          if (_loading)
            const Center(child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ))
          else ...[
            _StatusBadge(connection: _connection),
            const SizedBox(height: 20),

            if (_connection != null && _connection!.isActive)
              _ConnectedView(
                connection:  _connection!,
                onDisconnect: _connecting ? null : _disconnect,
                loading:     _connecting,
              )
            else
              _DisconnectedView(
                onConnect: _connecting ? null : _startConnect,
                loading:   _connecting,
              ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ],
        ],
      ),
    );
  }
}

// ── BADGE DE ESTADO ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final WhatsAppConnection? connection;
  const _StatusBadge({this.connection});

  @override
  Widget build(BuildContext context) {
    final active = connection?.isActive ?? false;
    final color  = active ? const Color(0xFF25D366) : AppColors.textSecondary;
    final label  = active ? 'Conectado' : 'Sin conectar';
    final icon   = active ? Icons.check_circle_outline : Icons.phone_disabled_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── VISTA CONECTADO ────────────────────────────────────────────────────────────

class _ConnectedView extends StatelessWidget {
  final WhatsAppConnection connection;
  final VoidCallback?      onDisconnect;
  final bool               loading;

  const _ConnectedView({
    required this.connection,
    required this.onDisconnect,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (connection.phoneNumber != null)
          _InfoRow(label: 'Número', value: connection.phoneNumber!),
        if (connection.phoneNumberId != null)
          _InfoRow(label: 'Phone Number ID', value: connection.phoneNumberId!),
        if (connection.wabaId != null)
          _InfoRow(label: 'WABA ID', value: connection.wabaId!),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onDisconnect,
          icon: loading
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
              : const Icon(Icons.link_off, size: 16, color: AppColors.danger),
          label: const Text('Desconectar número',
              style: TextStyle(color: AppColors.danger, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace')),
      ],
    ),
  );
}

// ── VISTA DESCONECTADO ─────────────────────────────────────────────────────────

class _DisconnectedView extends StatelessWidget {
  final VoidCallback? onConnect;
  final bool          loading;

  const _DisconnectedView({required this.onConnect, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conectá el número de WhatsApp de tu negocio. '
          'Serás redirigido a Meta para autorizar el acceso.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onConnect,
          icon: loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.link, size: 16),
          label: const Text('Conectar con Meta', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1877F2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}
