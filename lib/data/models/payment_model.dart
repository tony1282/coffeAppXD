// data/models/payment_model.dart

import 'package:flutter/foundation.dart';
import '../../core/error/error_messages.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/validators.dart';

class Payment {
  final int? id;
  final String? orderId;
  final double amount;
  final String method;
  final String status;
  final DateTime createdAt;

  static const List<String> _validStatuses = ['pending', 'completed', 'failed', 'refunded'];
  static const List<String> _validMethods = ['card', 'oxxo', 'bank_transfer', 'cash'];

  Payment({
    this.id,
    this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    // amount
    final amount = json['amount'];
    double parsedAmount;
    if (amount is int) {
      parsedAmount = amount.toDouble();
    } else if (amount is double) {
      parsedAmount = amount;
    } else if (amount is String) {
      parsedAmount = double.tryParse(amount) ?? 0.0;
    } else {
      if (kDebugMode) AppLogger.debug('Payment: amount inválido');
      throw FormatException(ErrorMessages.invalidResponse);
    }

    // method
    final method = json['payment_method']?.toString().toLowerCase() ?? '';
    final validMethod = _validMethods.contains(method) ? method : 'cash';

    // status
    final status = json['status']?.toString().toLowerCase() ?? 'pending';
    final validStatus = _validStatuses.contains(status) ? status : 'pending';

    // createdAt
    final createdAtStr = json['created_at'];
    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = createdAtStr != null
          ? DateTime.parse(createdAtStr.toString())
          : DateTime.now();
    } catch (_) {
      parsedCreatedAt = DateTime.now();
      if (kDebugMode) AppLogger.debug('Payment: created_at inválido');
    }

    // id
    int? parsedId;
    final id = json['id'];
    if (id != null) {
      if (id is int) {
        parsedId = id;
      } else if (id is String) {
        parsedId = int.tryParse(id);
      }
    }

    return Payment(
      id: parsedId,
      orderId: json['order_id']?.toString(),
      amount: parsedAmount,
      method: validMethod,
      status: validStatus,
      createdAt: parsedCreatedAt,
    );
  }
}