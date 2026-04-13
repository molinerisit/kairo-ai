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

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading  => _isLoading;
  String? get error   => _error;

  // checkSession: se llama al iniciar la app para ver si ya hay sesión activa.
  Future<void> checkSession() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    notifyListeners(); // notifica a los widgets que deben redibujarse
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService.login(email: email, password: password);
      _isLoggedIn = true;
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
    _error = null;
    notifyListeners();
  }
}
