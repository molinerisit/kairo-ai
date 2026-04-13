import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../../features/auth/auth_provider.dart';

// Definición de cada item del sidebar.
// Separar los datos de la UI hace más fácil agregar/quitar items.
class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}

const _navItems = [
  _NavItem(icon: Icons.grid_view_rounded,    label: 'Dashboard',       route: '/dashboard'),
  _NavItem(icon: Icons.table_chart_outlined, label: 'Tabla',           route: '/dashboard/tabla'),
  _NavItem(icon: Icons.calendar_month_outlined, label: 'Calendario',   route: '/dashboard/calendario'),
  _NavItem(icon: Icons.chat_bubble_outline,  label: 'Conversaciones',  route: '/dashboard/conversaciones'),
  _NavItem(icon: Icons.settings_outlined,    label: 'Configuración',   route: '/dashboard/configuracion'),
];

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    // GoRouterState.of(context).uri.path sería la forma correcta,
    // pero usamos la ruta del GoRouter para determinar el item activo.
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del sidebar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KAIRO AI',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Panel de control',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Divider(color: AppColors.border, height: 1),
          ),

          // Items de navegación
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: _navItems.map((item) {
                  final isActive = currentRoute.startsWith(item.route) &&
                      (item.route != '/dashboard' || currentRoute == '/dashboard');

                  return _SidebarItem(
                    item: item,
                    isActive: isActive,
                    onTap: () => context.go(item.route),
                  );
                }).toList(),
              ),
            ),
          ),

          // Botón de logout en la parte inferior
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: AppColors.border, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _SidebarItem(
              item: const _NavItem(
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                route: '',
              ),
              isActive: false,
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
