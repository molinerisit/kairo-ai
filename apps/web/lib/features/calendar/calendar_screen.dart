import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'calendar_provider.dart';
import 'calendar_service.dart';
import '../../shared/theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = CalendarProvider();
    _provider.loadEvents();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: const _CalendarView(),
    );
  }
}

// ── VISTA PRINCIPAL ────────────────────────────────────────────────────────────

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final month    = provider.month;
    final label    = '${_monthNames[month.month - 1]} ${month.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                Text('Calendario', style: Theme.of(context).textTheme.headlineLarge),
                const Spacer(),
                // Navegación de mes
                IconButton(
                  onPressed: () => provider.setMonth(
                    DateTime(month.year, month.month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: 'Mes anterior',
                ),
                Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                IconButton(
                  onPressed: () => provider.setMonth(
                    DateTime(month.year, month.month + 1),
                  ),
                  icon: const Icon(Icons.chevron_right, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: 'Mes siguiente',
                ),
                const SizedBox(width: 8),
                // Botón refresh
                IconButton(
                  onPressed: provider.loading ? null : provider.loadEvents,
                  icon: provider.loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : const Icon(Icons.refresh_outlined, size: 18),
                  color: AppColors.textSecondary,
                  tooltip: 'Actualizar',
                ),
                const SizedBox(width: 8),
                // Botón nuevo evento
                FilledButton.icon(
                  onPressed: () => _showNewEventDialog(context, provider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nuevo evento'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const Text(
              'Turnos y eventos del mes',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // ── Error banner ──────────────────────────────────────────────────
            if (provider.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                    Text(provider.error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                ),
              ),

            // ── Lista de eventos ──────────────────────────────────────────────
            Expanded(
              child: provider.loading && provider.events.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : provider.events.isEmpty
                      ? _EmptyState(month: label)
                      : _EventList(events: provider.events),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNewEventDialog(BuildContext context, CalendarProvider provider) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const _NewEventDialog(),
      ),
    );
  }
}

// ── LISTA DE EVENTOS ───────────────────────────────────────────────────────────

class _EventList extends StatelessWidget {
  final List<CalendarEvent> events;
  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, i) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _EventCard(event: events[i]),
    );
  }
}

// ── TARJETA DE EVENTO ──────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  const _EventCard({required this.event});

  static const _statusConfig = {
    'scheduled':  (label: 'Programado', color: AppColors.warning),
    'confirmed':  (label: 'Confirmado', color: AppColors.success),
    'cancelled':  (label: 'Cancelado',  color: AppColors.danger),
    'completed':  (label: 'Completado', color: AppColors.textSecondary),
  };

  static const _statusOrder = ['scheduled', 'confirmed', 'completed', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CalendarProvider>();
    final cfg = _statusConfig[event.status]
        ?? (label: event.status, color: AppColors.textSecondary);

    final contactName  = event.contactData['name']  as String?;
    final contactPhone = event.contactData['phone'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Franja de color según estado
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: cfg.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),

          // Fecha/hora
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _dayLabel(event.startsAt),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cfg.color),
              ),
              Text(
                _timeLabel(event.startsAt, event.endsAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Info principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(event.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
                if (contactName != null || contactPhone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        [contactName, contactPhone].whereType<String>().join(' \u00b7 '),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Badge de estado + menú
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cfg.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(cfg.label,
                    style: TextStyle(color: cfg.color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    await provider.deleteEvent(event.id);
                  } else {
                    await provider.updateStatus(event.id, value);
                  }
                },
                color: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                itemBuilder: (_) => [
                  ..._statusOrder
                      .where((s) => s != event.status)
                      .map((s) => PopupMenuItem(
                            value: s,
                            child: Text(
                              _statusConfig[s]!.label,
                              style: TextStyle(color: _statusConfig[s]!.color, fontSize: 13),
                            ),
                          )),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Eliminar', style: TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                ],
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // "13" (número del día)
  static String _dayLabel(DateTime dt) => dt.day.toString();

  // "14:00 – 15:00"
  static String _timeLabel(DateTime from, DateTime to) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(from.hour)}:${pad(from.minute)} – ${pad(to.hour)}:${pad(to.minute)}';
  }
}

// ── ESTADO VACÍO ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String month;
  const _EmptyState({required this.month});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month_outlined, size: 48, color: AppColors.border),
          const SizedBox(height: 16),
          Text('Sin eventos en $month',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Creá un evento con el botón "Nuevo evento".',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── DIALOG NUEVO EVENTO ────────────────────────────────────────────────────────

class _NewEventDialog extends StatefulWidget {
  const _NewEventDialog();

  @override
  State<_NewEventDialog> createState() => _NewEventDialogState();
}

class _NewEventDialogState extends State<_NewEventDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();

  DateTime? _startsAt;
  DateTime? _endsAt;
  bool      _saving = false;
  String?   _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? (_startsAt ?? now) : (_endsAt ?? now)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startsAt = dt;
        // Si el fin es anterior, ajustarlo
        if (_endsAt != null && _endsAt!.isBefore(dt)) {
          _endsAt = dt.add(const Duration(hours: 1));
        }
      } else {
        _endsAt = dt;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null || _endsAt == null) {
      setState(() => _error = 'Seleccioná fecha de inicio y fin.');
      return;
    }
    if (_endsAt!.isBefore(_startsAt!)) {
      setState(() => _error = 'La fecha de fin debe ser posterior al inicio.');
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      await context.read<CalendarProvider>().createEvent(
        title:        _titleCtrl.text.trim(),
        description:  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        startsAt:     _startsAt!,
        endsAt:       _endsAt!,
        contactName:  _nameCtrl.text.trim().isEmpty  ? null : _nameCtrl.text.trim(),
        contactPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text('Nuevo evento',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Título
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Título *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),

                // Descripción
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Fechas
                Row(
                  children: [
                    Expanded(child: _DateButton(
                      label: 'Inicio',
                      value: _startsAt,
                      onTap: () => _pickDateTime(true),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _DateButton(
                      label: 'Fin',
                      value: _endsAt,
                      onTap: () => _pickDateTime(false),
                    )),
                  ],
                ),
                const SizedBox(height: 16),

                // Contacto
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Nombre del contacto'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Teléfono'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),

                // Error
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ],

                const SizedBox(height: 24),

                // Acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Crear evento', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── BOTÓN DE FECHA ─────────────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String    label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String pad(int n) => n.toString().padLeft(2, '0');
    final text = value == null
        ? label
        : '${value!.day}/${value!.month}/${value!.year} ${pad(value!.hour)}:${pad(value!.minute)}';
    final color = value == null ? AppColors.textSecondary : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
