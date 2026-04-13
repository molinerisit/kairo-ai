import 'package:flutter/material.dart';
import '../../shared/widgets/sidebar.dart';

// DashboardShell es el layout persistente del panel de control.
// Tiene el sidebar a la izquierda y el contenido a la derecha.
//
// "Shell" es un patrón de go_router: un widget que envuelve
// las rutas hijas sin destruirse al navegar entre ellas.
// Así el sidebar no parpadea al cambiar de sección.
//
// child es la pantalla actual según la ruta — lo inyecta go_router.
class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AppSidebar(),
          // Expanded: ocupa todo el espacio restante después del sidebar
          Expanded(child: child),
        ],
      ),
    );
  }
}
