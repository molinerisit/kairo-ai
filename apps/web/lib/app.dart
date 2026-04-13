import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_shell.dart';
import 'features/dashboard/dashboard_home.dart';
import 'features/tables/table_screen.dart';
import 'features/conversations/conversation_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/theme/app_theme.dart';

// _router se crea fuera de la clase para que no se reconstruya en cada rebuild.
// refreshListenable conecta el router con el AuthProvider:
// cada vez que notifyListeners() se llama en AuthProvider,
// el router reevalúa el redirect — si ya no está logueado, redirige a /login.
GoRouter _buildRouter(AuthProvider auth) => GoRouter(
  initialLocation: '/login',
  refreshListenable: auth, // escucha cambios en el estado de auth
  redirect: (context, state) {
    final loggedIn   = auth.isLoggedIn;
    final goingLogin = state.uri.path == '/login';

    // Si no está logueado y no va a /login → redirigir a /login
    if (!loggedIn && !goingLogin) return '/login';

    // Si ya está logueado y va a /login → redirigir al dashboard
    if (loggedIn && goingLogin)  return '/dashboard';

    return null; // no redirigir
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // ShellRoute: mantiene el DashboardShell (sidebar) mientras
    // navega entre las subrutas. El sidebar no se destruye.
    ShellRoute(
      builder: (context, router, child) => DashboardShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardHome(),
        ),
        GoRoute(
          path: '/dashboard/tabla',
          builder: (context, state) => const TableScreen(),
        ),
        GoRoute(
          path: '/dashboard/calendario',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/dashboard/conversaciones',
          builder: (context, state) => const ConversationScreen(),
        ),
        GoRoute(
          path: '/dashboard/configuracion',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

// Pantalla placeholder para rutas que aún no están implementadas
class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            const Text(
              'Próximamente — en construcción.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class KairoApp extends StatefulWidget {
  const KairoApp({super.key});

  @override
  State<KairoApp> createState() => _KairoAppState();
}

class _KairoAppState extends State<KairoApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router       = _buildRouter(_authProvider);
    // Verificar si hay sesión guardada al arrancar la app
    _authProvider.checkSession();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider hace disponible el AuthProvider
    // a todos los widgets descendientes via context.watch/read
    return ChangeNotifierProvider.value(
      value: _authProvider,
      child: MaterialApp.router(
        title: 'Kairo AI',
        theme: AppTheme.dark,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
