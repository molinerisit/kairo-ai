import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'table_provider.dart';
import 'table_service.dart';
import 'widgets/table_grid.dart';
import '../../shared/theme/app_theme.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late final TableProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = TableProvider();
    // Cargar tablas al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) => _provider.loadTables());
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
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildTopBar(),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Consumer<TableProvider>(
      builder: (context, provider, _) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Título de la tabla seleccionada
            Text(
              provider.selectedTable?.name ?? 'Tablas',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            // Selector de tabla (si hay más de una)
            if (provider.tables.length > 1) ...[
              const SizedBox(width: 16),
              _TableSelector(
                tables: provider.tables,
                selected: provider.selectedTable,
                onSelect: provider.selectTable,
              ),
            ],

            const Spacer(),

            // Botón nueva fila
            if (provider.selectedTable != null)
              FilledButton.icon(
                onPressed: provider.addRow,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nueva fila'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),

            const SizedBox(width: 8),

            // Botón nueva tabla
            OutlinedButton.icon(
              onPressed: () => _showCreateTableDialog(context),
              icon: const Icon(Icons.table_chart_outlined, size: 16),
              label: const Text('Nueva tabla'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<TableProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingTables) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (provider.error != null) {
          return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.danger)));
        }
        if (provider.tables.isEmpty) {
          return _buildNoTablesState(context);
        }
        return const TableGrid();
      },
    );
  }

  Widget _buildNoTablesState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.table_chart_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Sin tablas todavía', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Creá tu primera tabla para organizar clientes, leads o turnos.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateTableDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Crear primera tabla'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // Dialog para crear una tabla nueva con columnas iniciales
  void _showCreateTableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateTableDialog(
        onCreated: (table) {
          _provider.tables.add(table);
          _provider.selectTable(table);
        },
      ),
    );
  }
}

// Selector de tabla: dropdown simple cuando hay más de una tabla
class _TableSelector extends StatelessWidget {
  final List<TableDefinition> tables;
  final TableDefinition? selected;
  final void Function(TableDefinition) onSelect;

  const _TableSelector({
    required this.tables,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selected?.id,
      underline: const SizedBox(),
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      dropdownColor: AppColors.surface,
      items: tables.map((t) => DropdownMenuItem(
        value: t.id,
        child: Text(t.name),
      )).toList(),
      onChanged: (id) {
        final table = tables.firstWhere((t) => t.id == id);
        onSelect(table);
      },
    );
  }
}

// Dialog para crear una tabla nueva
class _CreateTableDialog extends StatefulWidget {
  final void Function(TableDefinition) onCreated;
  const _CreateTableDialog({required this.onCreated});

  @override
  State<_CreateTableDialog> createState() => _CreateTableDialogState();
}

class _CreateTableDialogState extends State<_CreateTableDialog> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  // Columnas por defecto para que la tabla no empiece vacía
  final _defaultColumns = [
    {'name': 'Nombre',   'type': 'text',   'required': true},
    {'name': 'Teléfono', 'type': 'phone',  'required': false},
    {'name': 'Estado',   'type': 'status', 'required': false,
     'options': ['Nuevo', 'En proceso', 'Cerrado']},
    {'name': 'Notas',    'type': 'text',   'required': false},
  ];

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final table = await TableService.createTable(
        name: _nameCtrl.text.trim(),
        columns: _defaultColumns,
      );
      if (mounted) {
        widget.onCreated(table);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Nueva tabla', style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Nombre de la tabla'),
          ),
          const SizedBox(height: 12),
          const Text('Columnas iniciales: Nombre, Teléfono, Estado, Notas',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: _loading ? null : _create,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Crear'),
        ),
      ],
    );
  }
}
