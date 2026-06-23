// lib/core/security/payment_result.dart
//
// Reemplaza el bool? que retornaba el WebView.
// bool? tenía 3 estados: true/false/null — ambiguo y propenso a errores.
// Este enum hace el contrato explícito.

enum PaymentResult {
  /// El usuario llegó a la back_url de éxito
  success,

  /// El usuario llegó a la back_url de fallo
  failure,

  /// El usuario llegó a la back_url de pendiente (ej. OXXO)
  pending,

  /// El usuario cerró el WebView manualmente sin completar el flujo
  cancelled,
}