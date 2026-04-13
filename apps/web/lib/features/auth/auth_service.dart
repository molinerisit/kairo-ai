import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// URL base de la API — en desarrollo apunta al backend local.
// En producción se reemplaza por la URL real del servidor.
const String _apiBase = 'http://localhost:3000';

// Clave usada para guardar el JWT en SharedPreferences (localStorage en web).
const String _tokenKey = 'access_token';

class AuthService {
  // login: llama a POST /api/auth/login y guarda el JWT localmente.
  // Devuelve true si fue exitoso, lanza una excepción con el mensaje si falla.
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
      // Guardamos el token en SharedPreferences.
      // En Flutter Web, SharedPreferences usa localStorage del navegador.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, body['access_token'] as String);
      return;
    }

    // Lanzamos el mensaje de error del servidor para mostrarlo en la UI
    throw Exception(body['error'] ?? 'Error al iniciar sesión');
  }

  // logout: elimina el token guardado localmente.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // getToken: devuelve el JWT guardado, o null si no hay sesión.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // isLoggedIn: true si hay un token guardado.
  // No verifica que el token sea válido — eso lo hace el servidor.
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
