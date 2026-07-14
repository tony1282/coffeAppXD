// lib/models/user_model.dart

import 'package:flutter/foundation.dart';

class UserModel {
  final String userId;
  final String userName;
  final String userEmail;
  final String photoUrl;
  final String rol;
  final String? phone;
  final DateTime? fechaRegistro;

  // ============================================================
  // CONFIGURACIÓN DE SEGURIDAD
  // ============================================================
  static const List<String> _validRoles = ['cliente', 'admin'];
  static const int _maxUserIdLength = 128;
  static const int _maxUserNameLength = 100;
  static const int _maxUserEmailLength = 254;
  static const int _maxPhotoUrlLength = 500;

  // ✅ NUEVAS VALIDACIONES
  static const int _maxPhoneLength = 20;

  static const String _defaultRole = 'cliente';

  UserModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.photoUrl,
    this.rol = _defaultRole,
    this.phone,
    this.fechaRegistro,
  });

  // ============================================================
  // VALIDACIONES DEFENSIVAS
  // ============================================================
  static bool _isValidUserId(dynamic userId) {
    if (userId == null) return false;
    if (userId is! String) return false;
    final trimmed = userId.trim();
    return trimmed.isNotEmpty && trimmed.length <= _maxUserIdLength;
  }

  static bool _isValidUserName(dynamic name) {
    if (name == null) return false;
    if (name is! String) return false;
    final trimmed = name.trim();
    return trimmed.isNotEmpty && trimmed.length <= _maxUserNameLength;
  }

  static bool _isValidUserEmail(dynamic email) {
    if (email == null) return false;
    if (email is! String) return false;
    final trimmed = email.trim();
    if (trimmed.isEmpty || trimmed.length > _maxUserEmailLength) return false;

    // Validación básica de formato email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(trimmed);
  }

  static bool _isValidPhotoUrl(dynamic url) {
    if (url == null) return true; // Opcional
    if (url is! String) return false;
    return url.length <= _maxPhotoUrlLength;
  }

  // ✅ VALIDACIÓN PHONE
  static bool _isValidPhone(dynamic phone) {
    if (phone == null) return true;
    if (phone is! String) return false;

    final trimmed = phone.trim();

    if (trimmed.length > _maxPhoneLength) return false;

    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');

    return phoneRegex.hasMatch(trimmed);
  }

  static bool _isValidRol(dynamic rol) {
    if (rol == null) return true;
    if (rol is! String) return false;
    final normalized = rol.trim().toLowerCase();
    return _validRoles.contains(normalized);
  }

  static String _normalizeRol(dynamic rol) {
    if (rol == null) return _defaultRole;
    if (rol is! String) return _defaultRole;

    final normalized = rol.trim().toLowerCase();

    return _validRoles.contains(normalized)
        ? normalized
        : _defaultRole;
  }

  // ============================================================
  // GETTERS
  // ============================================================

  // ✅ isAdmin basado en string normalizado (case-insensitive)
  bool get isAdmin => rol == 'admin';

  // ============================================================
  // TO MAP
  // ============================================================
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'photoUrl': photoUrl,
      'rol': rol,
      if (phone != null) 'phone': phone,
      if (fechaRegistro != null) 'fecha_registro': fechaRegistro!.toIso8601String(),
    };
  }

  // ============================================================
  // FROM MAP (CON VALIDACIONES DEFENSIVAS)
  // ============================================================
  factory UserModel.fromMap(Map<String, dynamic> map) {

    // ✅ Validación de userId (CRÍTICO)
    final userId = map['userId'];

    if (!_isValidUserId(userId)) {
      if (kDebugMode) {
        print('[UserModel] userId inválido: $userId');
      }

      throw FormatException('userId inválido');
    }

    // ✅ Validación de userName
    final userName = map['userName'];

    if (!_isValidUserName(userName)) {
      if (kDebugMode) {
        print('[UserModel] userName inválido: $userName');
      }
    }

    // ✅ Validación de userEmail (CRÍTICO para comunicación)
    final userEmail = map['userEmail'];

    if (!_isValidUserEmail(userEmail)) {
      if (kDebugMode) {
        print('[UserModel] userEmail inválido: $userEmail');
      }
    }

    // ✅ Validación de photoUrl
    final photoUrl = map['photoUrl'];

    if (!_isValidPhotoUrl(photoUrl)) {
      if (kDebugMode) {
        print('[UserModel] photoUrl inválido, ignorando');
      }
    }

    // ✅ VALIDACIÓN PHONE
    final phone = map['phone'];

    if (!_isValidPhone(phone)) {
      if (kDebugMode) {
        print('[UserModel] phone inválido, ignorando');
      }
    }

    // ✅ Validación de rol (CRÍTICO para autorización)
    final rol = map['rol'];

    if (!_isValidRol(rol)) {
      if (kDebugMode) {
        print('[UserModel] rol inválido: $rol, usando $_defaultRole');
      }
    }

    final normalizedRol = _normalizeRol(rol);

    // fechaRegistro
    DateTime? parsedFechaRegistro;
    final fechaRaw = map['fecha_registro'] ?? map['createdAt'];
    if (fechaRaw != null) {
      try {
        parsedFechaRegistro = fechaRaw is DateTime
            ? fechaRaw
            : DateTime.parse(fechaRaw.toString());
      } catch (_) {}
    }

    return UserModel(
      userId: userId.toString().trim(),
      userName: userName?.toString().trim() ?? 'Usuario',
      userEmail: userEmail?.toString().trim() ?? '',
      photoUrl: photoUrl?.toString() ?? '',
      rol: normalizedRol,
      phone: _isValidPhone(phone) ? phone?.toString().trim() : null,
      fechaRegistro: parsedFechaRegistro,
    );
  }

  // ============================================================
  // COPYWITH (para rollback en providers)
  // ============================================================
  UserModel copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? photoUrl,
    String? rol,
    String? phone,
    DateTime? fechaRegistro,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      photoUrl: photoUrl ?? this.photoUrl,
      rol: rol ?? this.rol,
      phone: phone ?? this.phone,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}