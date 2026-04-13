import 'package:flutter/material.dart';
import 'table_service.dart';

class TableProvider extends ChangeNotifier {
  List<TableDefinition> tables = [];
  TableDefinition? selectedTable;
  List<DynamicRow> rows = [];

  bool isLoadingTables = false;
  bool isLoadingRows   = false;
  String? error;

  Future<void> loadTables() async {
    isLoadingTables = true;
    error = null;
    notifyListeners();
    try {
      tables = await TableService.listTables();
      // Si hay tablas, seleccionar la primera automáticamente
      if (tables.isNotEmpty && selectedTable == null) {
        await selectTable(tables.first);
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingTables = false;
      notifyListeners();
    }
  }

  Future<void> selectTable(TableDefinition table) async {
    selectedTable = table;
    rows = [];
    notifyListeners();
    await loadRows(table.id);
  }

  Future<void> loadRows(String tableId) async {
    isLoadingRows = true;
    notifyListeners();
    try {
      rows = await TableService.listRows(tableId);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingRows = false;
      notifyListeners();
    }
  }

  Future<void> addRow() async {
    if (selectedTable == null) return;
    try {
      // Crear fila vacía — el usuario la llena con edición inline
      final newRow = await TableService.createRow(selectedTable!.id, {});
      rows.add(newRow);
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> updateCell(
    String rowId,
    String columnId,
    dynamic value,
  ) async {
    if (selectedTable == null) return;
    try {
      await TableService.updateRow(selectedTable!.id, rowId, {columnId: value});
      // Actualizar el estado local sin recargar toda la tabla (optimismo parcial)
      final idx = rows.indexWhere((r) => r.id == rowId);
      if (idx != -1) {
        rows[idx].data[columnId] = value;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> deleteRow(String rowId) async {
    if (selectedTable == null) return;
    try {
      await TableService.deleteRow(selectedTable!.id, rowId);
      rows.removeWhere((r) => r.id == rowId);
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
