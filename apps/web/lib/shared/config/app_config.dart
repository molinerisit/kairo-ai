// Configuración global de la app.
// En desarrollo: los valores default apuntan a localhost.
// En producción: se inyectan en el build con --dart-define.
//
// Uso en build:
//   flutter build web --dart-define=API_BASE_URL=https://kairo-api.up.railway.app

/// URL base de la API. Inyectada en build con --dart-define=API_BASE_URL.
const String kApiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://kairo-api-production-5af7.up.railway.app',
);
