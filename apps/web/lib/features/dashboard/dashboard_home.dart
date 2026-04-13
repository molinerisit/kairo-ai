import 'package:flutter/material.dart';
import '../../shared/api/api_client.dart';
import '../../shared/theme/app_theme.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  Map<String, int>? _stats;
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiClient.get('/api/stats') as Map<String, dynamic>;
      setState(() {
        _stats = {
          'totalConversations': data['totalConversations'] as int,
          'openConversations':  data['openConversations']  as int,
          'eventsToday':        data['eventsToday']        as int,
          'totalRows':          data['totalRows']          as int,
          'messagesToday':      data['messagesToday']      as int,
        };
      });
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
            Row(
              children: [
                Text('Dashboard', style: Theme.of(context).textTheme.headlineLarge),
                const Spacer(),
                // Botón de refresh manual
                IconButton(
                  onPressed: _loading ? null : _loadStats,
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : const Icon(Icons.refresh_outlined, size: 18),
                  color: AppColors.textSecondary,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const Text(
              'Vista general del negocio',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            if (_error != null)
              Container(
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
                    Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                ),
              ),

            if (_stats != null) ...[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    label: 'Mensajes hoy',
                    value: '${_stats!['messagesToday']}',
                    icon: Icons.chat_bubble_outline,
                  ),
                  _StatCard(
                    label: 'Conversaciones abiertas',
                    value: '${_stats!['openConversations']}',
                    icon: Icons.forum_outlined,
                    color: _stats!['openConversations']! > 0 ? AppColors.warning : AppColors.primary,
                  ),
                  _StatCard(
                    label: 'Turnos hoy',
                    value: '${_stats!['eventsToday']}',
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.success,
                  ),
                  _StatCard(
                    label: 'Registros en tablas',
                    value: '${_stats!['totalRows']}',
                    icon: Icons.table_rows_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Resumen textual
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Agente secretario activo',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '${_stats!['totalConversations']} conversaciones totales · '
                            'Respondiendo por WhatsApp automáticamente',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Online',
                          style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
