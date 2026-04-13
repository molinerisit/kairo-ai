import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';

const String _apiBase = 'http://localhost:3000';

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
  // _authHeaders: agrega el JWT a cada request.
  // DEUDA TÉCNICA: idealmente esto estaría en un interceptor HTTP centralizado
  // para no repetirlo en cada método. Ver MANUAL.md sección de deuda técnica.
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<TableDefinition>> listTables() async {
    final response = await http.get(
      Uri.parse('$_apiBase/api/tables'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception('Error al cargar tablas');
    final List data = jsonDecode(response.body) as List;
    return data.map((t) => TableDefinition.fromJson(t as Map<String, dynamic>)).toList();
  }

  static Future<TableDefinition> createTable({
    required String name,
    required List<Map<String, dynamic>> columns,
    String tableType = 'custom',
  }) async {
    final response = await http.post(
      Uri.parse('$_apiBase/api/tables'),
      headers: await _authHeaders(),
      body: jsonEncode({'name': name, 'table_type': tableType, 'columns': columns}),
    );
    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Error al crear tabla');
    }
    return TableDefinition.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<List<DynamicRow>> listRows(String tableId) async {
    final response = await http.get(
      Uri.parse('$_apiBase/api/tables/$tableId/rows'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw Exception('Error al cargar filas');
    final List data = jsonDecode(response.body) as List;
    return data.map((r) => DynamicRow.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<DynamicRow> createRow(
    String tableId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$_apiBase/api/tables/$tableId/rows'),
      headers: await _authHeaders(),
      body: jsonEncode({'data': data}),
    );
    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Error al crear fila');
    }
    return DynamicRow.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> updateRow(
    String tableId,
    String rowId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$_apiBase/api/tables/$tableId/rows/$rowId'),
      headers: await _authHeaders(),
      body: jsonEncode({'data': data}),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Error al actualizar');
    }
  }

  static Future<void> deleteRow(String tableId, String rowId) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/api/tables/$tableId/rows/$rowId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 204) throw Exception('Error al eliminar fila');
  }
}
