import '../../shared/api/api_client.dart';

// Modelos de datos
class TableDefinition {
  final String id;
  final String name;
  final String tableType;
  final List<ColumnDefinition> columns;

  TableDefinition({
    required this.id,
    required this.name,
    required this.tableType,
    required this.columns,
  });

  factory TableDefinition.fromJson(Map<String, dynamic> json) => TableDefinition(
    id:        json['id'] as String,
    name:      json['name'] as String,
    tableType: json['table_type'] as String,
    columns:   (json['columns'] as List)
                 .map((c) => ColumnDefinition.fromJson(c as Map<String, dynamic>))
                 .toList(),
  );
}

class ColumnDefinition {
  final String id;
  final String name;
  final String type;
  final bool required;
  final List<String>? options;

  ColumnDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.required,
    this.options,
  });

  factory ColumnDefinition.fromJson(Map<String, dynamic> json) => ColumnDefinition(
    id:       json['id'] as String,
    name:     json['name'] as String,
    type:     json['type'] as String,
    required: json['required'] as bool? ?? false,
    options:  (json['options'] as List?)?.map((o) => o as String).toList(),
  );
}

class DynamicRow {
  final String id;
  final Map<String, dynamic> data;

  DynamicRow({required this.id, required this.data});

  factory DynamicRow.fromJson(Map<String, dynamic> json) => DynamicRow(
    id:   json['id'] as String,
    data: json['data'] as Map<String, dynamic>,
  );
}

// ── Servicio ──────────────────────────────────────────────────────

class TableService {
  static Future<List<TableDefinition>> listTables() async {
    final data = await ApiClient.get('/api/tables') as List;
    return data.map((t) => TableDefinition.fromJson(t as Map<String, dynamic>)).toList();
  }

  static Future<TableDefinition> createTable({
    required String name,
    required List<Map<String, dynamic>> columns,
    String tableType = 'custom',
  }) async {
    final data = await ApiClient.post('/api/tables', body: {
      'name': name,
      'table_type': tableType,
      'columns': columns,
    });
    return TableDefinition.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<DynamicRow>> listRows(String tableId) async {
    final data = await ApiClient.get('/api/tables/$tableId/rows') as List;
    return data.map((r) => DynamicRow.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<DynamicRow> createRow(String tableId, Map<String, dynamic> data) async {
    final result = await ApiClient.post('/api/tables/$tableId/rows', body: {'data': data});
    return DynamicRow.fromJson(result as Map<String, dynamic>);
  }

  static Future<void> updateRow(String tableId, String rowId, Map<String, dynamic> data) async {
    await ApiClient.put('/api/tables/$tableId/rows/$rowId', body: {'data': data});
  }

  static Future<void> deleteRow(String tableId, String rowId) async {
    await ApiClient.delete('/api/tables/$tableId/rows/$rowId');
  }
}
