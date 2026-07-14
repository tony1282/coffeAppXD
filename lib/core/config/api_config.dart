// lib/core/config/api_config.dart

class ApiConfig {
  static const String baseUrl =
      'https://boring-anteater-amenity.ngrok-free.dev/api';

  // ─────────────────────────────────────────────
  // Back URLs para Mercado Pago
  // ─────────────────────────────────────────────
  static const String backUrlBase =
      'https://boring-anteater-amenity.ngrok-free.dev';

  // Endpoints de Mercado Pago
  static const String mpCreatePreference =
      '$baseUrl/payments/create_preference';

  // Back URLs
  static const String mpSuccessUrl = '$backUrlBase/pago-exitoso';
  static const String mpFailureUrl = '$backUrlBase/pago-fallido';
  static const String mpPendingUrl = '$backUrlBase/pago-pendiente';

  // ✅ NUEVOS ENDPOINTS PARA REEMBOLSOS
  static const String refund = '$baseUrl/payments/refund/';
}
