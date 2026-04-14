import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _LegalNavbar(),
            _LegalContent(
              title: 'Política de Privacidad',
              lastUpdated: '13 de abril de 2026',
              sections: _privacySections,
            ),
            _LegalFooter(),
          ],
        ),
      ),
    );
  }
}

const _privacySections = [
  _LegalSection(
    title: '1. Información que recopilamos',
    content:
        'AXIIA recopila la siguiente información para prestar el servicio:\n\n'
        '• Información de cuenta: nombre, dirección de correo electrónico y contraseña al registrarte.\n'
        '• Información del negocio: nombre, descripción, servicios, horarios y preguntas frecuentes que cargás en la plataforma.\n'
        '• Datos de conversaciones: los mensajes de WhatsApp que tus clientes envían a tu número de negocio y las respuestas generadas por el agente.\n'
        '• Datos técnicos: dirección IP, tipo de navegador y registros de actividad del servidor para mantener la seguridad del servicio.',
  ),
  _LegalSection(
    title: '2. Cómo usamos tu información',
    content:
        'Usamos la información recopilada para:\n\n'
        '• Proveer, operar y mejorar el servicio de AXIIA.\n'
        '• Generar respuestas automáticas a través del agente de inteligencia artificial.\n'
        '• Mostrarte el historial de conversaciones en el panel de control.\n'
        '• Enviarte notificaciones relacionadas con tu cuenta (nunca publicidad de terceros).\n'
        '• Cumplir obligaciones legales y resolver disputas.',
  ),
  _LegalSection(
    title: '3. Mensajes de WhatsApp',
    content:
        'AXIIA procesa mensajes de WhatsApp a través de la Meta WhatsApp Cloud API. Al usar el servicio:\n\n'
        '• Los mensajes de tus clientes son procesados para generar respuestas automáticas.\n'
        '• Los mensajes se almacenan en nuestra base de datos para mostrarte el historial.\n'
        '• No compartimos el contenido de los mensajes con terceros, salvo requerimiento legal.\n'
        '• El uso de WhatsApp está sujeto también a los Términos y Políticas de Meta Platforms.',
  ),
  _LegalSection(
    title: '4. Compartir información con terceros',
    content:
        'No vendemos ni alquilamos tu información personal. Podemos compartir datos con:\n\n'
        '• Meta Platforms: para el envío y recepción de mensajes via WhatsApp Cloud API.\n'
        '• OpenAI: para el procesamiento de lenguaje natural y generación de respuestas del agente. Los mensajes procesados están sujetos a la política de privacidad de OpenAI.\n'
        '• Proveedores de infraestructura (Railway, Supabase): para hospedar y mantener el servicio.',
  ),
  _LegalSection(
    title: '5. Retención de datos',
    content:
        'Conservamos tus datos mientras tu cuenta esté activa. Podés solicitar la eliminación de tu cuenta y todos los datos asociados escribiendo a hola@getaxiia.com. '
        'Los mensajes de conversaciones se retienen por defecto por 12 meses.\n\n'
        'Algunos datos pueden retenerse por más tiempo si es necesario para cumplir obligaciones legales.',
  ),
  _LegalSection(
    title: '6. Seguridad',
    content:
        'Implementamos medidas técnicas y organizativas para proteger tu información:\n\n'
        '• Comunicaciones cifradas con HTTPS/TLS.\n'
        '• Contraseñas almacenadas con hash bcrypt.\n'
        '• Tokens JWT con expiración corta y refresh tokens.\n'
        '• Acceso restringido a datos por tenant (aislamiento multi-tenant).',
  ),
  _LegalSection(
    title: '7. Tus derechos',
    content:
        'Tenés derecho a:\n\n'
        '• Acceder a los datos personales que tenemos sobre vos.\n'
        '• Corregir información incorrecta.\n'
        '• Solicitar la eliminación de tu cuenta y datos.\n'
        '• Exportar tus conversaciones.\n\n'
        'Para ejercer estos derechos, escribí a hola@getaxiia.com.',
  ),
  _LegalSection(
    title: '8. Cookies',
    content:
        'AXIIA no utiliza cookies de seguimiento ni publicidad. Solo utilizamos almacenamiento local en el navegador para mantener tu sesión iniciada de forma segura.',
  ),
  _LegalSection(
    title: '9. Cambios a esta política',
    content:
        'Podemos actualizar esta política ocasionalmente. Te notificaremos por correo electrónico ante cambios significativos. '
        'El uso continuado del servicio tras la notificación implica aceptación de los nuevos términos.',
  ),
  _LegalSection(
    title: '10. Contacto',
    content:
        'Para preguntas sobre esta política de privacidad:\n\n'
        'Email: hola@getaxiia.com\n'
        'Sitio web: getaxiia.com',
  ),
];

// ── TERMS SCREEN ───────────────────────────────────────────────────────────────

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _LegalNavbar(),
            _LegalContent(
              title: 'Términos de Uso',
              lastUpdated: '13 de abril de 2026',
              sections: _termsSections,
            ),
            _LegalFooter(),
          ],
        ),
      ),
    );
  }
}

const _termsSections = [
  _LegalSection(
    title: '1. Aceptación de los términos',
    content:
        'Al crear una cuenta o usar AXIIA, aceptás estos Términos de Uso. Si no estás de acuerdo con alguna parte, '
        'no debés usar el servicio. Nos reservamos el derecho de modificar estos términos con previo aviso.',
  ),
  _LegalSection(
    title: '2. Descripción del servicio',
    content:
        'AXIIA es una plataforma SaaS que permite a negocios crear agentes de inteligencia artificial para automatizar '
        'la atención al cliente a través de WhatsApp Business. El servicio incluye:\n\n'
        '• Panel de administración web.\n'
        '• Integración con WhatsApp Cloud API (Meta).\n'
        '• Agente de IA configurable con información del negocio.\n'
        '• Historial de conversaciones.',
  ),
  _LegalSection(
    title: '3. Registro y cuentas',
    content:
        'Para usar AXIIA debés:\n\n'
        '• Ser mayor de 18 años o tener autorización de un representante legal.\n'
        '• Proporcionar información veraz y actualizada.\n'
        '• Mantener la confidencialidad de tus credenciales.\n'
        '• Notificarnos inmediatamente sobre accesos no autorizados a tu cuenta.\n\n'
        'Sos responsable de todas las actividades que ocurran bajo tu cuenta.',
  ),
  _LegalSection(
    title: '4. Uso aceptable',
    content:
        'Te comprometés a no usar AXIIA para:\n\n'
        '• Enviar spam, mensajes masivos no solicitados o contenido inapropiado.\n'
        '• Violar los Términos de Servicio de Meta/WhatsApp Business.\n'
        '• Actividades ilegales, fraudulentas o que violen derechos de terceros.\n'
        '• Recopilar datos de usuarios sin su consentimiento.\n'
        '• Intentar acceder a cuentas de otros usuarios.',
  ),
  _LegalSection(
    title: '5. WhatsApp y Meta',
    content:
        'El uso de WhatsApp a través de AXIIA está sujeto a los Términos de Servicio de WhatsApp Business y '
        'las Políticas de uso de la plataforma de Meta. Sos responsable de:\n\n'
        '• Cumplir con las políticas de mensajería de WhatsApp.\n'
        '• Obtener el consentimiento de tus clientes para recibir mensajes automatizados.\n'
        '• No usar el servicio para actividades que violen las políticas de Meta.',
  ),
  _LegalSection(
    title: '6. Propiedad intelectual',
    content:
        'AXIIA y todo su contenido (código, diseño, marca) son propiedad exclusiva de sus creadores. '
        'Se te otorga una licencia limitada, no exclusiva, para usar el servicio según estos términos.\n\n'
        'El contenido que cargás (información de tu negocio, mensajes) sigue siendo de tu propiedad. '
        'Nos otorgás una licencia para procesarlo con el único fin de prestar el servicio.',
  ),
  _LegalSection(
    title: '7. Disponibilidad y cambios',
    content:
        'Nos esforzamos por mantener AXIIA disponible 24/7, pero no garantizamos disponibilidad ininterrumpida. '
        'Podemos modificar, suspender o discontinuar funcionalidades con previo aviso cuando sea posible.',
  ),
  _LegalSection(
    title: '8. Limitación de responsabilidad',
    content:
        'En la máxima medida permitida por la ley, AXIIA no será responsable por:\n\n'
        '• Pérdidas de negocio, datos o ingresos derivadas del uso o imposibilidad de uso del servicio.\n'
        '• Respuestas del agente de IA que no sean precisas o apropiadas en todos los contextos.\n'
        '• Interrupciones del servicio de WhatsApp o Meta que estén fuera de nuestro control.\n\n'
        'La responsabilidad total de AXIIA no superará el monto pagado en los últimos 3 meses.',
  ),
  _LegalSection(
    title: '9. Cancelación',
    content:
        'Podés cancelar tu cuenta en cualquier momento escribiendo a hola@getaxiia.com. '
        'Nos reservamos el derecho de suspender o cancelar cuentas que violen estos términos, '
        'con o sin previo aviso dependiendo de la gravedad del incumplimiento.',
  ),
  _LegalSection(
    title: '10. Contacto',
    content:
        'Para consultas sobre estos términos:\n\n'
        'Email: hola@getaxiia.com\n'
        'Sitio web: getaxiia.com',
  ),
];

// ── COMPONENTES COMPARTIDOS ────────────────────────────────────────────────────

class _LegalSection {
  final String title;
  final String content;
  const _LegalSection({required this.title, required this.content});
}

class _LegalNavbar extends StatelessWidget {
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
          GestureDetector(
            onTap: () => context.go('/'),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 8),
                const Text('AXIIA', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.textSecondary),
            label: const Text('Inicio', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _LegalContent extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<_LegalSection> sections;

  const _LegalContent({required this.title, required this.lastUpdated, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Última actualización: $lastUpdated',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 48),
          ...sections.map((s) => _SectionBlock(section: s)),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final _LegalSection section;
  const _SectionBlock({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(section.content,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.7)),
        ],
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('© 2026 AXIIA', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 24),
          TextButton(
            onPressed: () => context.go('/privacy'),
            child: const Text('Privacidad', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          TextButton(
            onPressed: () => context.go('/terms'),
            child: const Text('Términos', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
