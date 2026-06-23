// lib/core/config/order_status_config.dart

import 'package:flutter/material.dart';
import '../../../core/config/constants.dart';

class OrderStatusConfig {
  // ============================================================
  // FLUJO DE ESTADOS (SOLO INGLÉS)
  // ============================================================
  static const List<String> flow = [
    'pending',
    'confirmed',
    'preparing',
    'shipped',
    'delivered',
  ];

  // ============================================================
  // MAPA DE NORMALIZACIÓN (SOLO INGLÉS)
  // ============================================================
  static const Map<String, String> statusMap = {
    // Backend (inglés)
    'pending': 'pending',
    'confirmed': 'confirmed',
    'preparing': 'preparing',
    'shipped': 'shipped',
    'delivered': 'delivered',
    'cancelled': 'cancelled',
    // Español → Inglés (para compatibilidad)
    'pendiente': 'pending',
    'preparando': 'preparing',
    'listo': 'shipped',
    'entregado': 'delivered',
    'cancelado': 'cancelled',
  };

  // ============================================================
  // COLORES
  // ============================================================
  static const Map<String, Color> colors = {
    'pending': Color(0xFFFFB347),    // Ámbar
    'confirmed': Color(0xFF3B5EFF),  // Azul
    'preparing': Color(0xFF4CAF7D),  // Verde
    'shipped': Color(0xFF8B5CF6),    // Púrpura
    'delivered': Color(0xFF8A8A8A),  // Gris
    'cancelled': Color(0xFFE05555),  // Rojo
  };

  // ============================================================
  // ETIQUETAS (PARA MOSTRAR EN ESPAÑOL)
  // ============================================================
  static const Map<String, String> labels = {
    'pending': 'Pendiente',
    'confirmed': 'Preparando',
    'preparing': 'Listo',
    'shipped': 'En camino',
    'delivered': 'Entregado',
    'cancelled': 'Cancelado',
  };

  // ============================================================
  // ICONOS
  // ============================================================
  static const Map<String, IconData> icons = {
    'pending': Icons.schedule_rounded,
    'confirmed': Icons.local_fire_department_rounded,
    'preparing': Icons.check_circle_rounded,
    'shipped': Icons.delivery_dining_rounded,
    'delivered': Icons.home_rounded,
    'cancelled': Icons.cancel_rounded,
  };

  // ============================================================
  // SIGUIENTE ESTADO (para el botón "Avanzar")
  // ============================================================
  static const Map<String, String> nextStatus = {
    'pending': 'confirmed',
    'confirmed': 'preparing',
    'preparing': 'shipped',
    'shipped': 'delivered',
    'delivered': 'delivered',  // Estado final
    'cancelled': 'cancelled',  // Estado final
  };

  // ============================================================
  // STEPPER
  // ============================================================
  static const List<String> stepperSteps = ['Pedido', 'Cocina', 'Listo', 'En camino', 'Entregado'];
  
  static const List<Color> stepperColors = [
    Color(0xFFFFB347),   // pending
    Color(0xFF3B5EFF),   // confirmed
    Color(0xFF4CAF7D),   // preparing
    Color(0xFF8B5CF6),   // shipped
    Color(0xFF8A8A8A),   // delivered
  ];

  // ============================================================
  // ESTADOS VÁLIDOS (SOLO INGLÉS)
  // ============================================================
  static const List<String> allStatuses = [
    'pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled',
  ];

  // ============================================================
  // PAGOS
  // ============================================================
  static const Map<String, Color> paymentColors = {
    'pagado':   AppColors.success,
    'pendiente': AppColors.warning,
    'fallido':  AppColors.error,
  };

  static const Map<String, String> paymentLabels = {
    'pagado':   'Pago confirmado',
    'pendiente': 'Pago pendiente',
    'fallido':  'Pago fallido',
  };

  static const Map<String, IconData> paymentIcons = {
    'pagado':   Icons.check_circle_rounded,
    'pendiente': Icons.schedule_rounded,
    'fallido':  Icons.cancel_rounded,
  };
}