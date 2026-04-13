import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _apiBase       = 'http://localhost:3000';
const String _accessKey     = 'access_token';
const String _refreshKey    = 'refresh_token';
const String _emailKey      = 'user_email';

class AuthService {
  // login: llama a POST /api/auth/login y persiste ambos tokens.
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiBase/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey,  body['access_token']  as String);
      await prefs.setString(_refreshKey, body['refresh_token'] as String);
      final user = body['user'] as Map<String, dynamic>?;
      if (user != null) await prefs.setString(_emailKey, user['email'] as String? ?? '');
      return;
    }

    throw Exception(body['error'] ?? 'Error al iniciar sesión');
  }

  // logout: llama al endpoint del servidor para revocar los refresh tokens,
  // luego limpia el storage local.
  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      // Intentamos revocar en el servidor (best-effort — si falla igual limpiamos local)
      try {
        await http.post(
          Uri.parse('$_apiBase/api/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {
        // Si no se puede contactar al servidor, igual hacemos logout local
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_emailKey);
  }

  // getUserEmail: devuelve el email del usuario logueado (guardado al hacer login).
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // getToken: devuelve el access token guardado, o null si no hay sesión.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  // refreshToken: intenta renovar el access token usando el refresh token.
  // Si falla (refresh vencido), devuelve false → hay que re-loguearse.
  static Future<bool> refreshToken() async {
    final prefs        = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshKey);

    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse('$_apiBase/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      await prefs.setString(_accessKey,  body['access_token']  as String);
      await prefs.setString(_refreshKey, body['refresh_token'] as String);
      return true;
    }

    // Refresh inválido o vencido → limpiar y forzar re-login
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    return false;
  }

  // isLoggedIn: true si hay tokens guardados.
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
