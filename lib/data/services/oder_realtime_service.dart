// lib/data/services/order_realtime_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/logger.dart';

/// Mantiene una conexión WebSocket con el backend para recibir
/// notificaciones en tiempo real cuando el admin cambia el estado
/// de un pedido del usuario actual.
class OrderRealtimeService {
  OrderRealtimeService._();
  static final OrderRealtimeService instance = OrderRealtimeService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _shouldReconnect = false;

  /// Callback que se dispara con el JSON del pedido actualizado.
  void Function(Map<String, dynamic> orderJson)? onOrderUpdated;

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    _shouldReconnect = true;
    await _connectInternal();
  }

  Future<void> _connectInternal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) {
        AppLogger.debug('OrderRealtimeService: Usuario no autenticado, no se conecta');
      }
      return;
    }

    try {
      final token = await user.getIdToken(false);

      // Construir URL WebSocket
      final wsBase = ApiConfig.baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');

      final uri = Uri.parse('$wsBase/orders/ws?token=$token');

      if (kDebugMode) {
        AppLogger.debug('OrderRealtimeService: Conectando a $uri');
      }

      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (event) {
          try {
            final data = jsonDecode(event as String) as Map<String, dynamic>;
            if (data['type'] == 'order_status_updated' &&
                data['order'] is Map<String, dynamic>) {
              onOrderUpdated?.call(data['order'] as Map<String, dynamic>);
            }
          } catch (e) {
            if (kDebugMode) {
              AppLogger.error('OrderRealtimeService: parseo de mensaje', e);
            }
          }
        },
        onDone: _scheduleReconnect,
        onError: (e) {
          if (kDebugMode) {
            AppLogger.error('OrderRealtimeService: error en socket', e);
          }
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      if (kDebugMode) {
        AppLogger.debug('OrderRealtimeService: conectado');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('OrderRealtimeService: fallo al conectar', e);
      }
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _channel = null;
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_shouldReconnect) _connectInternal();
    });
  }

  void disconnect() {
    if (kDebugMode) {
      AppLogger.debug('OrderRealtimeService: desconectando');
    }
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}