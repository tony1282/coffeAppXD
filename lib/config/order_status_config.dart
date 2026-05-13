// lib/screens/admin/widgets/shared/order_status_config.dart

import 'package:flutter/material.dart';
import '../../../config/constants.dart';

class OrderStatusConfig {
  static const List<String> flow = [
    'pendiente',
    'preparando',
    'listo',
    'entregado',
  ];

  static const Map<String, Color> colors = {
    'pendiente': AppColors.pending,
    'preparando': AppColors.preparing,
    'listo': AppColors.ready,
    'entregado': AppColors.delivered,
  };

  static const Map<String, String> labels = {
    'pendiente': 'Pendiente',
    'preparando': 'Preparando',
    'listo': 'Listo',
    'entregado': 'Entregado',
  };

  static const Map<String, IconData> icons = {
    'pendiente': Icons.schedule_rounded,
    'preparando': Icons.local_fire_department_rounded,
    'listo': Icons.check_circle_rounded,
    'entregado': Icons.where_to_vote_rounded,
  };

  static const List<String> stepperSteps = ['Pedido', 'Cocina', 'Listo', 'Entregado'];
  
  static const Map<int, Color> stepperColors = {
    0: AppColors.pending,
    1: AppColors.preparing,
    2: AppColors.ready,
    3: AppColors.delivered,
  };
}