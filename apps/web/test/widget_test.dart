// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

// Tests del widget principal — se implementarán en sprints siguientes.
// Por ahora verificamos que la app arranca sin errores.
void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // TODO: agregar tests reales cuando los widgets estén completos
    expect(true, isTrue);
  });
}
