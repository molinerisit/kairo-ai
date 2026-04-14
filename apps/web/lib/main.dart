import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';

void main() {
  // usePathUrlStrategy: cambia el routing de hash (#/) a path real (/privacy).
  // Debe llamarse ANTES de WidgetsFlutterBinding para que tome efecto.
  // Requiere que el servidor sirva index.html para todas las rutas (vercel.json ya lo hace).
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AxiiaApp());
}
