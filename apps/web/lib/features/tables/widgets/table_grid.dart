import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../table_provider.dart';
import '../../../shared/theme/app_theme.dart';
import 'table_cell_editor.dart';

// La grilla de la tabla: header + filas editables.
// Scroll horizontal si hay muchas columnas, vertical para las filas.
class TableGrid extends StatelessWidget {
  const TableGrid({super.key});

  static const double _colWidth    = 180.0;
  static const double _rowHeight   = 40.0;
  static const double _actionWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TableProvider>();
    final table    = provider.selectedTable;

    if (table == null) {
      return const Center(
        child: Text('Seleccioná una tabla', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    if (provider.isLoadingRows) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final columns = table.columns;
    final rows    = provider.rows;
    final totalWidth = columns.length * _colWidth + _actionWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scroll horizontal para tablas con muchas columnas
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              children: [
                _buildHeader(columns),
                const Divider(height: 1, color: AppColors.border),
              ],
            ),
          ),
        ),

        // Filas con scroll vertical
        Expanded(
          child: rows.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalWidth,
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, i) => _buildRow(context, rows[i], columns, i),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // Header: nombre de cada columna
  Widget _buildHeader(List columns) {
    return Container(
      height: _rowHeight,
      color: AppColors.surfaceLight,
      child: Row(
        children: [
          ...columns.map((col) => SizedBox(
            width: _colWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                col.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )),
          // Columna de acciones (eliminar)
          SizedBox(width: _actionWidth),
        ],
      ),
    );
  }

  // Una fila con sus celdas editables
  Widget _buildRow(BuildContext context, dynamic row, List columns, int index) {
    final isEven = index % 2 == 0;

    return Container(
      height: _rowHeight,
      color: isEven ? Colors.transparent : AppColors.surfaceLight.withValues(alpha: 0.3),
      child: Row(
        children: [
          ...columns.map((col) => EditableCell(
            rowId:    row.id,
            column:   col,
            value:    row.data[col.id],
            width:    _colWidth,
            onSave:   (rowId, colId, value) =>
                context.read<TableProvider>().updateCell(rowId, colId, value),
          )),
          // Botón de eliminar fila
          SizedBox(
            width: _actionWidth,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              color: AppColors.textSecondary,
              hoverColor: AppColors.danger.withValues(alpha: 0.1),
              onPressed: () => _confirmDelete(context, row.id),
              tooltip: 'Eliminar fila',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.table_rows_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text('Sin filas todavía', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text(
            'Hacé click en "+ Nueva fila" para agregar',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String rowId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar fila', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          '¿Estás seguro? Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<TableProvider>().deleteRow(rowId);
    }
  }
}
