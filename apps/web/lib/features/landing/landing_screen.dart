import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Navbar(),
            _HeroSection(),
            _FeaturesSection(),
            _HowItWorksSection(),
            _CtaSection(),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

// ── NAVBAR ─────────────────────────────────────────────────────────────────────

class _Navbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'AXIIA',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Nav links
          TextButton(
            onPressed: () => context.go('/privacy'),
            child: const Text('Privacidad', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.go('/terms'),
            child: const Text('Términos', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () => context.go('/login'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ingresar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── HERO ────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 100),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Powered by Meta WhatsApp Cloud API',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Título principal
          const Text(
            'AXIIA',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 72,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Asistentes virtuales para WhatsApp\ncon Inteligencia Artificial',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 22,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Automatizá la atención al cliente de tu negocio.\nTu agente responde 24/7, aprende de tu negocio y convierte consultas en ventas.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // CTA buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => context.go('/register'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Comenzar gratis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Iniciar sesión', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── FEATURES ────────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
      color: AppColors.surface,
      child: Column(
        children: [
          const Text(
            '¿Qué hace AXIIA?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Todo lo que necesitás para automatizar tu atención al cliente',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 56),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureCard(
                icon: Icons.smart_toy_outlined,
                title: 'Agente con IA',
                description: 'Tu asistente entiende preguntas en lenguaje natural y responde con la información de tu negocio.',
              ),
              _FeatureCard(
                icon: Icons.schedule_outlined,
                title: 'Disponible 24/7',
                description: 'Nunca más pierdas una consulta. AXIIA atiende clientes a cualquier hora, todos los días.',
              ),
              _FeatureCard(
                icon: Icons.storefront_outlined,
                title: 'Configurá tu negocio',
                description: 'Cargá tus servicios, horarios y preguntas frecuentes. El agente aprende y responde por vos.',
              ),
              _FeatureCard(
                icon: Icons.forum_outlined,
                title: 'Historial completo',
                description: 'Todas las conversaciones guardadas. Revisá, exportá y entendé mejor a tus clientes.',
              ),
              _FeatureCard(
                icon: Icons.people_outline,
                title: 'Multi-tenant',
                description: 'Cada negocio tiene su propio espacio aislado con su configuración y conversaciones.',
              ),
              _FeatureCard(
                icon: Icons.verified_outlined,
                title: 'API oficial de Meta',
                description: 'Integración con WhatsApp Cloud API oficial. Sin apps de terceros ni cuentas no autorizadas.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}

// ── HOW IT WORKS ───────────────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
      child: Column(
        children: [
          const Text(
            'Cómo funciona',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'En tres pasos simples tu negocio tiene un asistente inteligente',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 56),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: const [
              _StepCard(
                number: '01',
                title: 'Conectás tu WhatsApp Business',
                description: 'Vinculás tu número de WhatsApp Business a través de la API oficial de Meta en minutos.',
                icon: Icons.link_outlined,
              ),
              _StepCard(
                number: '02',
                title: 'Configurás tu agente',
                description: 'Cargás la información de tu negocio: servicios, horarios, preguntas frecuentes y el tono del asistente.',
                icon: Icons.tune_outlined,
              ),
              _StepCard(
                number: '03',
                title: 'AXIIA responde automáticamente',
                description: 'Desde el primer mensaje, tu agente atiende, informa y gestiona consultas de tus clientes.',
                icon: Icons.auto_awesome_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({required this.number, required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                number,
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Icon(icon, color: AppColors.primary, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}

// ── CTA FINAL ──────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
      color: AppColors.surface,
      child: Column(
        children: [
          const Text(
            '¿Listo para automatizar\ntu atención al cliente?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Creá tu cuenta gratis y empezá a configurar tu agente hoy.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () => context.go('/register'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Crear cuenta gratis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── FOOTER ─────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AXIIA',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Asistentes virtuales para\nWhatsApp con IA',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
                  ),
                ],
              ),
              const Spacer(),
              // Links
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.go('/privacy'),
                    child: const Text('Política de privacidad', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () => context.go('/terms'),
                    child: const Text('Términos de uso', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'hola@getaxiia.com',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          const Text(
            '© 2026 AXIIA. Todos los derechos reservados.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
