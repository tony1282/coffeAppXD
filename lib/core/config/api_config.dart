// lib/core/config/api_config.dart
// lib/core/config/api_config.dart

class ApiConfig {
  static const String baseUrl =
      'https://boring-anteater-amenity.ngrok-free.dev/api';

  // ─────────────────────────────────────────────
  // Back URLs para Mercado Pago
  // Solo el dominio base, sin /api ni /webhooks
  // ─────────────────────────────────────────────
  static const String backUrlBase =
      'https://boring-anteater-amenity.ngrok-free.dev';

  // Endpoints de Mercado Pago
  static const String mpCreatePreference =
      '$baseUrl/payments/create_preference';

  // Back URLs — el usuario es redirigido aquí después de pagar
  static const String mpSuccessUrl = '$backUrlBase/pago-exitoso';
  static const String mpFailureUrl = '$backUrlBase/pago-fallido';
  static const String mpPendingUrl = '$backUrlBase/pago-pendiente';
}