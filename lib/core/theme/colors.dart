// lib/core/theme/colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // PRIMARY COLORS
  // ============================================================
  
  static const Color primary = Color(0xFF3B5EFF);      // Azul principal
  static const Color primaryDark = Color(0xFF283FCC);   // Azul oscuro
  static const Color primaryLight = Color(0xFF7B96FF);  // Azul claro
  
  // ============================================================
  // BACKGROUND & SURFACE
  // ============================================================
  
  static const Color background = Color(0xFFFFFBF8);    // Fondo blanco hueso
  static const Color card = Color(0xFFFFFFFF);          // Blanco puro para tarjetas
  static const Color surface = Color(0xFFF8F9FA);       // Gris muy claro
  
  // ============================================================
  // TEXT COLORS
  // ============================================================
  
  static const Color textDark = Color(0xFF1A1A1A);       // Negro suave
  static const Color textGrey = Color(0xFF8A8A8A);       // Gris secundario
  static const Color textLight = Color(0xFFBDBDBD);      // Gris claro
  
  // ============================================================
  // STATUS COLORS
  // ============================================================
  
  static const Color success = Color(0xFF4CAF7D);        // Verde
  static const Color warning = Color(0xFFFFB347);        // Ámbar
  static const Color error = Color(0xFFE05555);          // Rojo
  static const Color info = Color(0xFF3B5EFF);           // Azul
  
  // ============================================================
  // ORDER STATUS COLORS
  // ============================================================
  
  static const Color orderPending = Color(0xFFFFB347);    // Ámbar
  static const Color orderPreparing = Color(0xFFFFB347);  // Ámbar
  static const Color orderReady = Color(0xFF4CAF7D);      // Verde
  static const Color orderDelivered = Color(0xFF8A8A8A);  // Gris
  static const Color orderCancelled = Color(0xFFE05555);  // Rojo
  
  // ============================================================
  // DIVIDERS & BORDERS
  // ============================================================
  
  static const Color divider = Color(0xFFEEEEEE);
  static const Color border = Color(0xFFE0E0E0);
}