import 'package:flutter/material.dart';
import 'auth_service.dart';

// AuthProvider gestiona el estado de autenticación de la app.
// Extiende ChangeNotifier para notificar a los widgets cuando cambia el estado.
//
// Provider es el sistema de state management (gestión de estado) que usamos.
// El estado es cualquier dato que, cuando cambia, debe redibujar la UI.
// En este caso: si el usuario está logueado o no.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading  = false;
  String? _error;
  String? _userEmail;

  bool    get isLoggedIn => _isLoggedIn;
  bool    get isLoading  => _isLoading;
  String? get error      => _error;
  String? get userEmail  => _userEmail;

  // checkSession: verifica si hay sesión activa.
  // Si el access token vencido pero hay refresh token válido, renueva automáticamente.
  Future<void> checkSession() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    if (!_isLoggedIn) {
      // Intentar renovar con refresh token antes de declarar que no hay sesión
      _isLoggedIn = await AuthService.refreshToken();
    }
    if (_isLoggedIn) _userEmail = await AuthService.getUserEmail();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService.login(email: email, password: password);
      _isLoggedIn = true;
      _userEmail  = await AuthService.getUserEmail();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String businessName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService.register(
        email: email,
        password: password,
        businessName: businessName,
      );
      _isLoggedIn = true;
      _userEmail  = await AuthService.getUserEmail();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _isLoggedIn = false;
    _userEmail  = null;
    _error      = null;
    notifyListeners();
  }
}
