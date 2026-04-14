import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/dashboard/dashboard_shell.dart';
import 'features/dashboard/dashboard_home.dart';
import 'features/tables/table_screen.dart';
import 'features/conversations/conversation_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/legal/privacy_screen.dart';
import 'shared/theme/app_theme.dart';

// Rutas públicas: no requieren autenticación
const _publicRoutes = ['/', '/privacy', '/terms', '/login', '/register'];

GoRouter _buildRouter(AuthProvider auth) => GoRouter(
  initialLocation: '/',
  refreshListenable: auth,
  redirect: (context, state) {
    final loggedIn       = auth.isLoggedIn;
    final justRegistered = auth.justRegistered;
    final path           = state.uri.path;
    final isPublic       = _publicRoutes.contains(path);

    // Rutas públicas siempre accesibles sin auth
    if (isPublic) {
      // Si ya está logueado y va a login/register → dashboard
      if (loggedIn && (path == '/login' || path == '/register')) return '/dashboard';
      return null;
    }

    // Rutas privadas: sin sesión → login
    if (!loggedIn) return '/login';

    // Primera vez registrado → onboarding
    if (loggedIn && justRegistered && path != '/onboarding') return '/onboarding';

    return null;
  },
  routes: [
    // ── Rutas públicas ─────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsScreen(),
    ),

    // ── Auth ───────────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // ── Dashboard (requiere auth) ──────────────────────────────────
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

class AxiiaApp extends StatefulWidget {
  const AxiiaApp({super.key});

  @override
  State<AxiiaApp> createState() => _AxiiaAppState();
}

class _AxiiaAppState extends State<AxiiaApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router       = _buildRouter(_authProvider);
    _authProvider.checkSession();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authProvider,
      child: MaterialApp.router(
        title: 'AXIIA',
        theme: AppTheme.dark,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
