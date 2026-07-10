// lib/core/config/order_status_config.dart

import 'package:flutter/material.dart';
import '../../../core/config/constants.dart';

class OrderStatusConfig {
  // ─── FLUJO DE ESTADOS ──────────────────────────────────────
  static const List<String> flow = [
    'pending',
    'confirmed',
    'preparing',
    'shipped',
    'delivered',
  ];

  // ─── MAPA DE NORMALIZACIÓN ─────────────────────────────────
  static const Map<String, String> statusMap = {
    'pending': 'pending',
    'confirmed': 'confirmed',
    'preparing': 'preparing',
    'shipped': 'shipped',
    'delivered': 'delivered',
    'cancelled': 'cancelled',
    'pendiente': 'pending',
    'preparando': 'preparing',
    'listo': 'shipped',
    'entregado': 'delivered',
    'cancelado': 'cancelled',
  };

  // ─── LABELS PARA CLIENTE ───────────────────────────────────
  static const Map<String, String> clientLabels = {
    'pending': 'Recibido',
    'confirmed': 'Confirmado',
    'preparing': 'Preparando',
    'shipped': 'En camino',
    'delivered': 'Entregado',
    'cancelled': 'Cancelado',
  };

  // ─── LABELS PARA ADMIN ─────────────────────────────────────
  static const Map<String, String> adminLabels = {
    'pending': 'Pendiente',
    'confirmed': 'Confirmado',
    'preparing': 'Preparando',
    'shipped': 'En camino',
    'delivered': 'Entregado',
    'cancelled': 'Cancelado',
  };

  // ─── COLORES ───────────────────────────────────────────────
  static const Map<String, Color> colors = {
    'pending': Color(0xFFFFB347),
    'confirmed': Color(0xFF3B5EFF),
    'preparing': Color(0xFF4CAF7D),
    'shipped': Color(0xFF8B5CF6),
    'delivered': Color(0xFF8A8A8A),
    'cancelled': Color(0xFFE05555),
  };

  // ─── ICONOS ────────────────────────────────────────────────
  static const Map<String, IconData> icons = {
    'pending': Icons.schedule_rounded,
    'confirmed': Icons.local_fire_department_rounded,
    'preparing': Icons.check_circle_rounded,
    'shipped': Icons.delivery_dining_rounded,
    'delivered': Icons.home_rounded,
    'cancelled': Icons.cancel_rounded,
  };

  // ─── STEPPER PARA CLIENTE ──────────────────────────────────
  static const List<String> clientStepper = [
    'Recibido',
    'Confirmado',
    'Preparando',
    'En camino',
    'Entregado',
  ];

  // ─── STEPPER PARA ADMIN ────────────────────────────────────
  static const List<String> adminStepper = [
    'Pendiente',
    'Preparando',
    'Listo',
    'En camino',
  ];

  // ─── STEPPER ALIASES ───────────────────────────────────────
  static const List<String> stepperSteps = adminStepper;

  static const List<Color> stepperColors = [
    Color(0xFFFFB347),  // pending
    Color(0xFF4CAF7D),  // preparing
    Color(0xFF8B5CF6),  // shipped
    Color(0xFF8A8A8A),  // delivered
  ];

  // ─── PAYMENT COLORS ────────────────────────────────────────
  static const Map<String, Color> paymentColors = {
    'pending': AppColors.warning,
    'paid': AppColors.success,
    'completed': AppColors.success,
    'refunded': AppColors.error,
    'partial_refund': AppColors.warning,
    'failed': AppColors.error,
    'pagado': AppColors.success,
    'pendiente': AppColors.warning,
    'fallido': AppColors.error,
  };

  // ─── PAYMENT LABELS ────────────────────────────────────────
  static const Map<String, String> paymentLabels = {
    'pending': 'Pago pendiente',
    'paid': 'Pago completado',
    'completed': 'Pago completado',
    'refunded': 'Pago reembolsado',
    'partial_refund': 'Reembolso parcial',
    'failed': 'Pago fallido',
    'pagado': 'Pago confirmado',
    'pendiente': 'Pago pendiente',
    'fallido': 'Pago fallido',
  };

  // ─── PAYMENT ICONS ─────────────────────────────────────────
  static const Map<String, IconData> paymentIcons = {
    'pending': Icons.schedule_rounded,
    'paid': Icons.check_circle_rounded,
    'completed': Icons.check_circle_rounded,
    'refunded': Icons.currency_exchange_rounded,
    'partial_refund': Icons.currency_exchange_rounded,
    'failed': Icons.cancel_rounded,
    'pagado': Icons.check_circle_rounded,
    'pendiente': Icons.schedule_rounded,
    'fallido': Icons.cancel_rounded,
  };
}
