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
  // ✅ PAGOS - COMPLETO (todos los estados)
  // ============================================================
  static const Map<String, Color> paymentColors = {
    // ✅ ESTADOS DEL BACKEND
    'pending': AppColors.warning,
    'paid': AppColors.success,
    'completed': AppColors.success,
    'refunded': AppColors.error,
    'partial_refund': AppColors.warning,
    'failed': AppColors.error,
    'in_process': AppColors.warning,  // ← AGREGADO
    'rejected': AppColors.error,      // ← AGREGADO
    'cancelled': AppColors.error,     // ← AGREGADO
    'charged_back': AppColors.error,  // ← AGREGADO
    'voided': AppColors.error,        // ← AGREGADO
    
    // ⚠️ VALORES LEGACY (español) - para compatibilidad
    'pagado': AppColors.success,
    'pendiente': AppColors.warning,
    'fallido': AppColors.error,
  };

  static const Map<String, String> paymentLabels = {
    // ✅ ESTADOS DEL BACKEND
    'pending': 'Pago pendiente',
    'paid': 'Pago completado',
    'completed': 'Pago completado',
    'refunded': 'Pago reembolsado',
    'partial_refund': 'Reembolso parcial',
    'failed': 'Pago fallido',
    'in_process': 'Pago en proceso',   // ← AGREGADO
    'rejected': 'Pago rechazado',      // ← AGREGADO
    'cancelled': 'Pago cancelado',     // ← AGREGADO
    'charged_back': 'Contracargo',     // ← AGREGADO
    'voided': 'Pago anulado',          // ← AGREGADO
    
    // ⚠️ VALORES LEGACY (español) - para compatibilidad
    'pagado': 'Pago confirmado',
    'pendiente': 'Pago pendiente',
    'fallido': 'Pago fallido',
  };

  static const Map<String, IconData> paymentIcons = {
    // ✅ ESTADOS DEL BACKEND
    'pending': Icons.schedule_rounded,
    'paid': Icons.check_circle_rounded,
    'completed': Icons.check_circle_rounded,
    'refunded': Icons.currency_exchange_rounded,
    'partial_refund': Icons.currency_exchange_rounded,
    'failed': Icons.cancel_rounded,
    'in_process': Icons.hourglass_top_rounded,    // ← AGREGADO
    'rejected': Icons.block_rounded,              // ← AGREGADO
    'cancelled': Icons.cancel_rounded,            // ← AGREGADO
    'charged_back': Icons.report_problem_rounded, // ← AGREGADO
    'voided': Icons.remove_circle_rounded,        // ← AGREGADO
    
    // ⚠️ VALORES LEGACY (español) - para compatibilidad
    'pagado': Icons.check_circle_rounded,
    'pendiente': Icons.schedule_rounded,
    'fallido': Icons.cancel_rounded,
  };
}