import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized() inicializa el engine de Flutter.
  // Necesario cuando se usan plugins (shared_preferences, etc.)
  // antes de que corra el primer frame de la app.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AxiiaApp());
}
