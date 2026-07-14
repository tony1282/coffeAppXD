// lib/config/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  // Azul principal (un poco más claro que el original)
  static const primary = Color(0xFF3B5EFF); // Azul rey más vibrante
  static const primaryDark =
      Color(0xFF283FCC); // Azul más oscuro para hover/pressed
  static const primaryLight =
      Color(0xFF7B96FF); // Azul claro para fondos suaves

  // Fondo y textos
  static const background = Color(0xFFFFFBF8);
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF8A8A8A);
  static const card = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);
  static const divider = Color(0xFFEEEEEE);

  // Colores adicionales para admin (ajustados a la paleta azul)
  static const success = Color(0xFF4CAF7D); // Verde
  static const warning = Color(0xFFFFB347); // Ámbar
  static const error = Color(0xFFE05555); // Rojo

  // Estados de pedidos (con azul como principal)
  static const pending = Color(0xFF3B5EFF); // Azul para pendiente
  static const preparing = Color(0xFFFFB347); // Ámbar para preparando
  static const ready = Color(0xFF4CAF7D); // Verde para listo
  static const delivered = Color(0xFF8A8A8A); // Gris para entregado
  static const cancelled = Color(0xFFE05555); // Rojo para cancelado

  // Aliases para order status config
  static const orderPending = pending;
  static const orderPreparing = preparing;
  static const orderReady = ready;
  static const orderDelivered = delivered;
  static const orderCancelled = cancelled;

  // Colores azules adicionales
  static const blueLight = Color(0xFFEBF0FF); // Azul muy claro para fondos
  static const blueGrey = Color(0xFF5A6B8A); // Azul grisáceo
  static const navy = Color(0xFF1A2B5C); // Azul marino oscuro
}
