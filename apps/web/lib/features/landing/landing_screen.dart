import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── SISTEMA DE DISEÑO DEL LANDING (tema claro) ──────────────────────────────────
const _bg       = Color(0xFFF6F8FF); // base clara con leve tinte azul
const _surface  = Color(0xFFFFFFFF); // cards
const _border   = Color(0xFFE7ECF7); // borde suave
const _ink      = Color(0xFF0B1635); // navy de marca (títulos)
const _muted    = Color(0xFF5C6B8A); // texto secundario
const _accent   = Color(0xFF005BFE); // azul de marca
const _accentLt = Color(0xFF4D8BFF);
const _accent2  = Color(0xFF8FB6FF);
const _success  = Color(0xFF16A34A);
const _maxW     = 1180.0;

// Sombra suave para dar profundidad a las cards (en vez de borders duros).
const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x14123A7A), blurRadius: 28, spreadRadius: -6, offset: Offset(0, 14)),
];

// Elementos focales oscuros (mockup, snippet, CTA) para contraste sobre el claro.
const _darkGrad = LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: [Color(0xFF0C1838), Color(0xFF0A1228)],
);

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Fondo diseñado: gradiente claro + glows azules suaves (ambiente).
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0xFFEFF4FF), Color(0xFFF6F8FF)],
                  stops: [0.0, 0.32, 1.0],
                ),
              ),
            ),
          ),
          const Positioned(top: -180, right: -130, child: _GlowBlob(size: 560, color: _accent, opacity: 0.10)),
          const Positioned(top: 220, left: -160, child: _GlowBlob(size: 460, color: _accent2, opacity: 0.14)),
          const Positioned(bottom: 200, right: -160, child: _GlowBlob(size: 420, color: _accent, opacity: 0.07)),
          const SingleChildScrollView(
            child: Column(
              children: [
                _Navbar(),
                _HeroSection(),
                _StatsBand(),
                _FeaturesSection(),
                _ShowcaseSection(),
                _WidgetSection(),
                _HowItWorksSection(),
                _CtaSection(),
                _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── NAVBAR (glass claro) ─────────────────────────────────────────────────────────

class _Navbar extends StatelessWidget {
  const _Navbar();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 720;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 48, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xCCFFFFFF),
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxW),
              child: Row(
                children: [
                  const _GradientText('AXIIA',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  const Spacer(),
                  if (!narrow) ...[
                    _NavLink('Privacidad', () => context.go('/privacy')),
                    _NavLink('Términos', () => context.go('/terms')),
                    const SizedBox(width: 12),
                  ],
                  _GlowButton(label: 'Ingresar', onTap: () => context.go('/login'), compact: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w500)),
      );
}

// ── HERO ─────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final narrow = width < 900;

    final textCol = Column(
      crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _accent.withValues(alpha: 0.22)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            _PulseDot(),
            SizedBox(width: 8),
            Text('Powered by Meta WhatsApp Cloud API',
                style: TextStyle(color: _accent, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 28),
        _GradientText(
          'AXIIA',
          textAlign: narrow ? TextAlign.center : TextAlign.start,
          style: TextStyle(fontSize: narrow ? 64 : 92, fontWeight: FontWeight.w900, letterSpacing: 2, height: 1.0),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Tu asistente Kairos atiende, vende y responde 24/7 — por WhatsApp y en tu sitio web.',
            textAlign: narrow ? TextAlign.center : TextAlign.start,
            style: const TextStyle(color: _ink, fontSize: 22, height: 1.45, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            'Inteligencia artificial que aprende de tu negocio y convierte cada consulta en una oportunidad. Sin código, en minutos.',
            textAlign: narrow ? TextAlign.center : TextAlign.start,
            style: const TextStyle(color: _muted, fontSize: 16, height: 1.7),
          ),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: narrow ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _GlowButton(label: 'Comenzar gratis', icon: Icons.arrow_forward_rounded, onTap: () => context.go('/register')),
            _GhostButton(label: 'Ver cómo funciona', onTap: () => context.go('/login')),
          ],
        ),
        const SizedBox(height: 22),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: _success, size: 15),
            SizedBox(width: 8),
            Text('Sin tarjeta · Listo en minutos · Plan gratis para empezar',
                style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );

    final hero = narrow
        ? Column(children: [textCol, const SizedBox(height: 56), const _ChatMockup()])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 6, child: textCol),
              const SizedBox(width: 48),
              const Expanded(flex: 5, child: _ChatMockup()),
            ],
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 24 : 48, vertical: narrow ? 56 : 84),
      child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: _maxW), child: hero),
      ),
    );
  }
}

// ── MOCKUP DEL CHAT (oscuro, focal) ─────────────────────────────────────────────

class _ChatMockup extends StatelessWidget {
  const _ChatMockup();

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        decoration: BoxDecoration(
          gradient: _darkGrad,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _accent.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(color: _accent.withValues(alpha: 0.22), blurRadius: 70, spreadRadius: -12, offset: const Offset(0, 28)),
            const BoxShadow(color: Color(0x22123A7A), blurRadius: 30, offset: Offset(0, 14)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF11224A), Color(0xFF0C1838)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(children: [
                const _BlinkingKairos(size: 46),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Kairos', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  Row(children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(
                      color: _success, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _success.withValues(alpha: 0.7), blurRadius: 6)],
                    )),
                    const SizedBox(width: 6),
                    const Text('En línea · responde al instante', style: TextStyle(color: Colors.white60, fontSize: 11.5)),
                  ]),
                ]),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(children: [
                _Bubble(text: 'Hola! ¿Tienen turno para mañana a la tarde?', fromUser: true),
                SizedBox(height: 12),
                _Bubble(text: '¡Hola! 👋 Sí, tenemos lugar mañana 16:30 y 18:00. ¿Te reservo alguno a tu nombre?', fromUser: false),
                SizedBox(height: 12),
                _QuickChipsRow(),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool fromUser;
  const _Bubble({required this.text, required this.fromUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: fromUser ? const LinearGradient(colors: [_accent, Color(0xFF003ECC)]) : null,
            color: fromUser ? null : const Color(0xFF16264D),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(fromUser ? 16 : 4),
              bottomRight: Radius.circular(fromUser ? 4 : 16),
            ),
          ),
          child: Text(text, style: TextStyle(
            color: fromUser ? Colors.white : Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5)),
        ),
      ),
    );
  }
}

class _QuickChipsRow extends StatelessWidget {
  const _QuickChipsRow();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in const ['Reservar 16:30', 'Reservar 18:00', 'Ver precios'])
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _accent.withValues(alpha: 0.45)),
            ),
            child: Text(c, style: const TextStyle(color: _accentLt, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }
}

// ── BANDA DE STATS ──────────────────────────────────────────────────────────────

class _StatsBand extends StatelessWidget {
  const _StatsBand();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 720;
    return _Section(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 24 : 48, vertical: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: _softShadow,
        ),
        child: const Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 40, runSpacing: 24,
          children: [
            _Stat(value: '24/7', label: 'Siempre disponible'),
            _Stat(value: '2', label: 'Canales: WhatsApp + Web'),
            _Stat(value: '<5 s', label: 'Tiempo de respuesta'),
            _Stat(value: '0', label: 'Líneas de código'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        _GradientText(value, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
      ]);
}

// ── FEATURES ────────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(children: [
        const _SectionTitle('Todo lo que tu negocio necesita', 'Una plataforma, un asistente, todos tus canales'),
        const SizedBox(height: 52),
        const Wrap(
          spacing: 22, runSpacing: 22, alignment: WrapAlignment.center,
          children: [
            _GlowFeatureCard(icon: Icons.smart_toy_outlined, title: 'Agente con IA', description: 'Kairos entiende lenguaje natural y responde con la información real de tu negocio.'),
            _GlowFeatureCard(icon: Icons.bolt_outlined, title: 'Disponible 24/7', description: 'Nunca más pierdas una consulta. Atiende a cualquier hora, todos los días.'),
            _GlowFeatureCard(icon: Icons.auto_fix_high_outlined, title: 'Se configura solo', description: 'Aprende de tu sitio web: productos, precios y preguntas frecuentes, automático.'),
            _GlowFeatureCard(icon: Icons.forum_outlined, title: 'Bandeja unificada', description: 'WhatsApp y web en un solo inbox. Revisá, exportá y entendé a tus clientes.'),
            _GlowFeatureCard(icon: Icons.layers_outlined, title: 'Multi-tenant', description: 'Cada negocio con su espacio aislado, su configuración y sus conversaciones.'),
            _GlowFeatureCard(icon: Icons.verified_outlined, title: 'API oficial de Meta', description: 'WhatsApp Cloud API oficial. Sin apps de terceros ni cuentas no autorizadas.'),
          ],
        ),
      ]),
    );
  }
}

class _GlowFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, description;
  const _GlowFeatureCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      glow: true,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: _softShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _accent.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: _accent, size: 24),
          ),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Text(description, style: const TextStyle(color: _muted, fontSize: 13.5, height: 1.6)),
        ]),
      ),
    );
  }
}

// ── SHOWCASE (Kairos en acción) ─────────────────────────────────────────────────

class _ShowcaseSection extends StatelessWidget {
  const _ShowcaseSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(children: [
        const _SectionTitle('Kairos en acción', 'Lo mismo que ves acá, funcionando en negocios reales'),
        const SizedBox(height: 52),
        const Wrap(
          spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
          children: [
            _ShowcaseCard(image: 'assets/usecase_whatsapp.jpg', icon: Icons.chat_bubble_outline,
                title: 'Por WhatsApp', desc: 'Toma reservas, responde y vende 24/7 desde el chat.'),
            _ShowcaseCard(image: 'assets/usecase_ecommerce.jpg', icon: Icons.shopping_bag_outlined,
                title: 'En tu ecommerce', desc: 'El widget asesora al visitante y lo ayuda a comprar.'),
            _ShowcaseCard(image: 'assets/usecase_dashboard.jpg', icon: Icons.dashboard_outlined,
                title: 'Todo en un panel', desc: 'Conversaciones y métricas centralizadas en un lugar.'),
            _ShowcaseCard(image: 'assets/usecase_retail.jpg', icon: Icons.storefront_outlined,
                title: 'En el local', desc: 'Asiste a tu equipo de ventas en tiempo real.'),
          ],
        ),
      ]),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  final String image, title, desc;
  final IconData icon;
  const _ShowcaseCard({required this.image, required this.title, required this.desc, required this.icon});

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      glow: true,
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: _softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.asset(image, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _accent.withValues(alpha: 0.18)),
                ),
                child: Icon(icon, color: _accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: _muted, fontSize: 13, height: 1.5)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── WIDGET WEB INSTALABLE ───────────────────────────────────────────────────────

class _WidgetSection extends StatelessWidget {
  const _WidgetSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _success.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _success.withValues(alpha: 0.30)),
          ),
          child: const Text('NUEVO · Widget web',
              style: TextStyle(color: _success, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 22),
        const _SectionTitle('Kairos también vive en tu sitio web', 'Una línea de código. Se autoinstala y se configura solo.'),
        const SizedBox(height: 36),
        _HoverScale(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: _darkGrad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.18), blurRadius: 40, spreadRadius: -10, offset: const Offset(0, 16))],
            ),
            child: const Row(children: [
              Icon(Icons.code_rounded, color: _accentLt, size: 20),
              SizedBox(width: 14),
              Expanded(
                child: SelectableText(
                  '<script src="https://api.getaxiia.com/widget/kairos.js"\n        data-axiia-key="ax_tu-clave" defer></script>',
                  style: TextStyle(color: _accent2, fontSize: 13.5, height: 1.6, fontFamily: 'monospace'),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 44),
        const Wrap(
          spacing: 22, runSpacing: 22, alignment: WrapAlignment.center,
          children: [
            _GlowFeatureCard(icon: Icons.terminal_outlined, title: 'Una línea de código', description: 'Pegás el script en tu web y el widget aparece. Sin plugins ni complicaciones.'),
            _GlowFeatureCard(icon: Icons.travel_explore_outlined, title: 'Lee tu sitio', description: 'Analiza tu web y arma su base de conocimiento, saludo y opciones por vos.'),
            _GlowFeatureCard(icon: Icons.my_location_outlined, title: 'Te lleva a la sección', description: 'Cuando un visitante pregunta algo, lo lleva y resalta esa parte de tu página.'),
          ],
        ),
      ]),
    );
  }
}

// ── HOW IT WORKS ───────────────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(children: [
        const _SectionTitle('En tres pasos simples', 'De cero a un asistente inteligente atendiendo por vos'),
        const SizedBox(height: 52),
        const Wrap(
          spacing: 28, runSpacing: 28, alignment: WrapAlignment.center,
          children: [
            _StepCard(number: '01', title: 'Conectás tus canales', description: 'Vinculás WhatsApp con la API oficial de Meta y/o pegás el widget en tu sitio.', icon: Icons.link_rounded),
            _StepCard(number: '02', title: 'Kairos aprende', description: 'Cargás tu negocio o dejás que analice tu web: servicios, precios y FAQs.', icon: Icons.psychology_outlined),
            _StepCard(number: '03', title: 'Responde solo', description: 'Desde el primer mensaje atiende, informa y gestiona consultas 24/7.', icon: Icons.rocket_launch_outlined),
          ],
        ),
      ]),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number, title, description;
  final IconData icon;
  const _StepCard({required this.number, required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: _softShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _GradientText(number, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
            const Spacer(),
            Icon(icon, color: _accent, size: 26),
          ]),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: _muted, fontSize: 13.5, height: 1.6)),
        ]),
      ),
    );
  }
}

// ── CTA FINAL (panel oscuro focal) ──────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 720;
    return _Section(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: narrow ? 48 : 64),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0B1F4D), Color(0xFF0A1430)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: _accent.withValues(alpha: 0.28), blurRadius: 80, spreadRadius: -24, offset: const Offset(0, 30)),
          ],
        ),
        child: Column(children: [
          const _BlinkingKairos(size: 64),
          const SizedBox(height: 20),
          Text(
            '¿Listo para que Kairos\natienda por vos?',
            style: TextStyle(color: Colors.white, fontSize: narrow ? 28 : 38, fontWeight: FontWeight.w800, height: 1.25),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          const Text('Creá tu cuenta gratis y dejá tu asistente funcionando hoy.',
              style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _GlowButton(label: 'Crear cuenta gratis', icon: Icons.arrow_forward_rounded, onTap: () => context.go('/register')),
        ]),
      ),
    );
  }
}

// ── FOOTER ─────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 640;
    return _Section(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 24 : 48, vertical: 44),
      child: Column(children: [
        Flex(
          direction: narrow ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Column(crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: const [
              _GradientText('AXIIA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              SizedBox(height: 10),
              Text('Asistentes con IA para WhatsApp y web',
                  style: TextStyle(color: _muted, fontSize: 12.5, height: 1.6)),
            ]),
            if (!narrow) const Spacer(),
            if (narrow) const SizedBox(height: 24),
            Column(crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.end, children: [
              TextButton(onPressed: () => context.go('/privacy'),
                  child: const Text('Política de privacidad', style: TextStyle(color: _muted, fontSize: 13))),
              TextButton(onPressed: () => context.go('/terms'),
                  child: const Text('Términos de uso', style: TextStyle(color: _muted, fontSize: 13))),
              const SizedBox(height: 4),
              const Text('hola@getaxiia.com', style: TextStyle(color: _muted, fontSize: 12)),
            ]),
          ],
        ),
        const SizedBox(height: 28),
        const Divider(color: _border),
        const SizedBox(height: 16),
        const Text('© 2026 AXIIA. Todos los derechos reservados.',
            style: TextStyle(color: _muted, fontSize: 12), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  COMPONENTES REUTILIZABLES
// ═══════════════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _Section({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 720;
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: narrow ? 24 : 48, vertical: 72),
      child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: _maxW), child: child),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title, subtitle;
  const _SectionTitle(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    final big = MediaQuery.of(context).size.width >= 720;
    return Column(children: [
      Text(title,
          style: TextStyle(color: _ink, fontSize: big ? 34 : 27, fontWeight: FontWeight.w800, height: 1.2),
          textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(subtitle,
          style: const TextStyle(color: _muted, fontSize: 16, height: 1.5),
          textAlign: TextAlign.center),
    ]);
  }
}

// Texto con gradiente azul de marca vía ShaderMask.
class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  const _GradientText(this.text, {required this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [_accentLt, _accent, Color(0xFF003ECC)],
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, textAlign: textAlign, style: style.copyWith(color: Colors.white)),
    );
  }
}

// Botón principal con gradiente + glow + hover.
class _GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool compact;
  const _GlowButton({required this.label, required this.onTap, this.icon, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      scale: 1.04,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 28, vertical: compact ? 11 : 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accentLt, _accent]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.40), blurRadius: 22, spreadRadius: -4, offset: const Offset(0, 8))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: TextStyle(color: Colors.white, fontSize: compact ? 14 : 16, fontWeight: FontWeight.w700)),
              if (icon != null) ...[const SizedBox(width: 8), Icon(icon, color: Colors.white, size: compact ? 16 : 19)],
            ]),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
              boxShadow: _softShadow,
            ),
            child: Text(label, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

// Glow blob de fondo (círculo con gradiente radial difuso).
class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowBlob({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0.0)]),
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: _success, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: _success.withValues(alpha: 0.8), blurRadius: 8, spreadRadius: 1)],
        ),
      );
}

// ── Hover: levanta y escala (+ glow opcional) ──────────────────────────────────
class _HoverScale extends StatefulWidget {
  final Widget child;
  final double scale;
  final bool glow;
  const _HoverScale({required this.child, this.scale = 1.02, this.glow = false});

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.glow && _hover
                ? [BoxShadow(color: _accent.withValues(alpha: 0.28), blurRadius: 40, spreadRadius: -8, offset: const Offset(0, 16))]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Kairos pestañeando (swap de imágenes) ──────────────────────────────────────
class _BlinkingKairos extends StatefulWidget {
  final double size;
  const _BlinkingKairos({required this.size});

  @override
  State<_BlinkingKairos> createState() => _BlinkingKairosState();
}

class _BlinkingKairosState extends State<_BlinkingKairos> {
  bool _closed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    _timer = Timer(const Duration(milliseconds: 3400), () async {
      if (!mounted) return;
      setState(() => _closed = true);
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _closed = false);
      _scheduleBlink();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/kairos_open.png'), context);
    precacheImage(const AssetImage('assets/kairos_closed.png'), context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(children: [
        Image.asset('assets/kairos_open.png', width: widget.size, height: widget.size, fit: BoxFit.contain),
        Opacity(
          opacity: _closed ? 1 : 0,
          child: Image.asset('assets/kairos_closed.png', width: widget.size, height: widget.size, fit: BoxFit.contain),
        ),
      ]),
    );
  }
}
