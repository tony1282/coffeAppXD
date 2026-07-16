// lib/core/config/api_config.dart

class ApiConfig {
  static const String baseUrl =
      'https://boring-anteater-amenity.ngrok-free.dev/api';

  static const String authFirebaseEndpoint = '/auth/firebase/';
  static const String productsEndpoint = '/products/';
  static const String productsUploadImageEndpoint = '/products/upload-image';
  static const String ordersEndpoint = '/orders/';
  static const String cartEndpoint = '/cart/';
  static const String cartSyncEndpoint = '/cart/sync';
  static const String cartAddEndpoint = '/cart/add';
  static const String adminOrdersEndpoint = '/admin/orders';
  static const String paymentsMyEndpoint = '/payments/my/';
  static const String paymentsCreateEndpoint = '/payments/create/';
  static const String paymentsVerifyEndpoint = '/payments/verify/';
  static const String paymentsOrderEndpoint = '/payments/order/';
  static const String paymentsRefundEndpoint = '/payments/refund/';
  static const String salesEndpoint = '/sales/';

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

  static String buildUrl(String endpoint) {
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$normalizedEndpoint';
  }

  static Uri buildUri(String endpoint) => Uri.parse(buildUrl(endpoint));

  static String productPath([int? id]) {
    if (id == null) return productsEndpoint;
    return '${productsEndpoint}$id';
  }

  static String productAvailabilityPath(int id) => '${productsEndpoint}$id/availability';

  static String orderPath([int? id]) {
    if (id == null) return ordersEndpoint;
    return '${ordersEndpoint}$id/';
  }

  static String orderStatusPath(int id) => '${ordersEndpoint}$id/status';

  static String orderCancelPath(int id) => '${ordersEndpoint}$id/cancel';

  static String cartItemPath(int productId) => '${cartEndpoint}$productId';

  static String cartUpdatePath(int productId, {required int quantity}) =>
      '${cartEndpoint}$productId?quantity=$quantity';

  static String adminOrderStatusPath(int orderId) => '$adminOrdersEndpoint/$orderId/status';

  static String paymentVerifyPath(String preferenceId) =>
      '$paymentsVerifyEndpoint$preferenceId';

  static String paymentOrderPath(int orderId) => '$paymentsOrderEndpoint$orderId/';

  static String salesPath([String? periodo]) {
    if (periodo == null || periodo.isEmpty) return salesEndpoint;
    return '$salesEndpoint?periodo=$periodo';
  }
}
