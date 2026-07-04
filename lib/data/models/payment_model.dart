// lib/data/models/payment_model.dart

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
  
  // ✅ NUEVOS CAMPOS PARA REEMBOLSO
  final double? refundedAmount;
  final DateTime? refundedAt;
  final String? refundReason;
  final String? refundId;

  static const List<String> _validStatuses = [
    'pending', 'completed', 'failed', 'refunded', 'partial_refund'
  ];
  static const List<String> _validMethods = ['card', 'oxxo', 'bank_transfer', 'cash'];

  Payment({
    this.id,
    this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.refundedAmount,
    this.refundedAt,
    this.refundReason,
    this.refundId,
  });

  bool get isRefundable =>
      status == 'completed' &&
      (refundedAmount == null || refundedAmount! < amount);

  double get remainingRefundable =>
      isRefundable ? amount - (refundedAmount ?? 0) : 0;

  bool get isFullyRefunded =>
      refundedAmount != null && refundedAmount! >= amount;

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

    // refunded_amount
    double? parsedRefundedAmount;
    final refunded = json['refunded_amount'];
    if (refunded != null) {
      if (refunded is int) {
        parsedRefundedAmount = refunded.toDouble();
      } else if (refunded is double) {
        parsedRefundedAmount = refunded;
      } else if (refunded is String) {
        parsedRefundedAmount = double.tryParse(refunded);
      }
    }

    // refunded_at
    DateTime? parsedRefundedAt;
    final refundedAtStr = json['refunded_at'];
    if (refundedAtStr != null) {
      try {
        parsedRefundedAt = DateTime.parse(refundedAtStr.toString());
      } catch (_) {}
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
      refundedAmount: parsedRefundedAmount,
      refundedAt: parsedRefundedAt,
      refundReason: json['refund_reason'] as String?,
      refundId: json['refund_id'] as String?,
    );
  }
}