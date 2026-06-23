// lib/presentation/screens/payments/mercadopago_webview.dart
//
// Reemplaza _MercadoPagoWebView (clase privada en cart_screen).
// Ahora es una pantalla pública, reutilizable, con:
//   - Detección de URL exacta (no palabras genéricas como "success")
//   - Loading indicator mientras carga el checkout
//   - Manejo de error de carga de página
//   - Resultado tipado con PaymentResult

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/config/api_config.dart';
import '../../../core/security/payment_result.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class MercadoPagoWebView extends StatefulWidget {
  final String url;

  /// ID del pedido — solo para mostrar en AppBar
  final int orderId;

  const MercadoPagoWebView({
    super.key,
    required this.url,
    required this.orderId,
  });

  @override
  State<MercadoPagoWebView> createState() => _MercadoPagoWebViewState();
}

class _MercadoPagoWebViewState extends State<MercadoPagoWebView> {
  late final WebViewController _controller;
  bool _isPageLoading = true;
  bool _hasLoadError = false;

  // ──────────────────────────────────────────────────────────────
  // Back URLs — deben coincidir exactamente con las configuradas
  // en tu backend al crear la preferencia.
  // Usa tu dominio real en producción.
  // ──────────────────────────────────────────────────────────────
  static String get _successUrl => ApiConfig.mpSuccessUrl;
  static String get _failureUrl => ApiConfig.mpFailureUrl;
  static String get _pendingUrl => ApiConfig.mpPendingUrl;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isPageLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isPageLoading = false);
          },
          onWebResourceError: (error) {
            // Solo marcar error en fallos del documento principal
            if (error.isForMainFrame == true) {
              if (mounted) setState(() {
                _isPageLoading = false;
                _hasLoadError = true;
              });
            }
          },
          onUrlChange: (change) => _handleUrlChange(change.url),

          onNavigationRequest: (request) {
  final url = request.url;
  if (url.startsWith(_successUrl) ||
      url.startsWith(_failureUrl) ||
      url.startsWith(_pendingUrl)) {
    _handleUrlChange(url);
    return NavigationDecision.prevent; // ← bloquea que el WebView cargue la página
  }
  return NavigationDecision.navigate;
},
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _handleUrlChange(String? url) {
    if (url == null || !mounted) return;

    // ── Comparación exacta con startsWith para tolerar query params ──
    // Mercado Pago agrega ?collection_id=...&status=... a las back_urls
    if (url.startsWith(_successUrl)) {
      _pop(PaymentResult.success);
    } else if (url.startsWith(_failureUrl)) {
      _pop(PaymentResult.failure);
    } else if (url.startsWith(_pendingUrl)) {
      _pop(PaymentResult.pending);
    }
    // Si no coincide con ninguna back_url → el usuario sigue navegando
    // dentro del flujo de MP, no hacemos nada.
  }

  void _pop(PaymentResult result) {
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Confirmar si el usuario intenta cerrar con el botón atrás
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await _showCancelConfirm();
        if (confirm == true && mounted) {
          _pop(PaymentResult.cancelled);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pagar con Mercado Pago',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                'Pedido #${widget.orderId}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          // Botón X con confirmación
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final confirm = await _showCancelConfirm();
              if (confirm == true && mounted) {
                _pop(PaymentResult.cancelled);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            // ── WebView ──
            if (!_hasLoadError) WebViewWidget(controller: _controller),

            // ── Error de carga ──
            if (_hasLoadError) _ErrorView(onRetry: () {
              setState(() {
                _hasLoadError = false;
                _isPageLoading = true;
              });
              _controller.loadRequest(Uri.parse(widget.url));
            }),

            // ── Loading overlay ──
            if (_isPageLoading && !_hasLoadError)
              Container(
                color: AppColors.background,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando checkout seguro…',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showCancelConfirm() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '¿Cancelar pago?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Si cierras ahora, tu pago no será procesado.\nEl pedido quedará pendiente.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar pago'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar el checkout',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Verifica tu conexión e intenta de nuevo',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}