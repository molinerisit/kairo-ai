import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../features/auth/auth_service.dart';

// ApiClient — cliente HTTP centralizado.
//
// Problema que resuelve (DT-02): cada service repetía este patrón:
//   final token = await AuthService.getToken();
//   headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}
//
// Ahora todos los services usan ApiClient.get/post/put/patch/delete
// y el token se agrega automáticamente en _headers().
//
// También maneja el refresh automático: si una request devuelve 401,
// intenta renovar el token con el refresh token y reintenta la request.
// Si el refresh también falla, limpia la sesión y lanza una excepción
// que el AuthProvider puede capturar para redirigir al login.

const String apiBase = 'http://localhost:3000';

class ApiClient {
  // _headers: construye los headers con el token de autenticación.
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // _handleResponse: procesa la respuesta HTTP.
  // Si es 401 y hay refresh token, intenta renovar y reintenta la request.
  // Si el refresh falla, lanza SessionExpiredException para que el app redirija al login.
  static Future<dynamic> _handleResponse(
    http.Response response,
    Future<http.Response> Function() retry,
  ) async {
    if (response.statusCode == 401) {
      // Intentar renovar el token
      final refreshed = await AuthService.refreshToken();
      if (refreshed) {
        // Reintentar con el token nuevo
        final retried = await retry();
        return _parse(retried);
      } else {
        // El refresh también falló → sesión expirada definitivamente
        throw SessionExpiredException();
      }
    }
    return _parse(response);
  }

  // _parse: decodifica el JSON y lanza excepción si el status es error.
  static dynamic _parse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body is Map && body['error'] != null)
        ? body['error'] as String
        : 'Error ${response.statusCode}';
    throw ApiException(message, statusCode: response.statusCode);
  }

  // ── Métodos HTTP ────────────────────────────────────────────────

  static Future<dynamic> get(String path) async {
    final headers = await _headers();
    final response = await http.get(Uri.parse('$apiBase$path'), headers: headers);
    return _handleResponse(response, () async {
      final h = await _headers();
      return http.get(Uri.parse('$apiBase$path'), headers: h);
    });
  }

  static Future<dynamic> post(String path, {Object? body}) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$apiBase$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, () async {
      final h = await _headers();
      return http.post(Uri.parse('$apiBase$path'), headers: h,
          body: body != null ? jsonEncode(body) : null);
    });
  }

  static Future<dynamic> put(String path, {Object? body}) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$apiBase$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, () async {
      final h = await _headers();
      return http.put(Uri.parse('$apiBase$path'), headers: h,
          body: body != null ? jsonEncode(body) : null);
    });
  }

  static Future<dynamic> patch(String path, {Object? body}) async {
    final headers = await _headers();
    final response = await http.patch(
      Uri.parse('$apiBase$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, () async {
      final h = await _headers();
      return http.patch(Uri.parse('$apiBase$path'), headers: h,
          body: body != null ? jsonEncode(body) : null);
    });
  }

  static Future<void> delete(String path) async {
    final headers = await _headers();
    final response = await http.delete(Uri.parse('$apiBase$path'), headers: headers);
    await _handleResponse(response, () async {
      final h = await _headers();
      return http.delete(Uri.parse('$apiBase$path'), headers: h);
    });
  }
}

// Excepción para errores de la API con código HTTP
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, {required this.statusCode});

  @override
  String toString() => message;
}

// Excepción específica para sesión expirada (refresh falló)
// El AuthProvider la captura para hacer logout y redirigir al login.
class SessionExpiredException implements Exception {
  @override
  String toString() => 'Sesión expirada. Por favor iniciá sesión nuevamente.';
}
