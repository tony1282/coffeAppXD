class Payment {
  final int id;
  final int orderId;
  final String mercadoPagoPaymentId;  // ID de la transacción en MP
  final double amount;
  final String status;  // pending, approved, rejected, refunded
  final String paymentMethod;  // credit_card, debit_card, pix, mercadopago
  final DateTime createdAt;
  final DateTime? approvedAt;
  final Map<String, dynamic>? metadata;

  Payment({
    required this.id,
    required this.orderId,
    required this.mercadoPagoPaymentId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.approvedAt,
    this.metadata,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      orderId: json['order_id'],
      mercadoPagoPaymentId: json['mercado_pago_payment_id'],
      amount: json['amount'].toDouble(),
      status: json['status'],
      paymentMethod: json['payment_method'],
      createdAt: DateTime.parse(json['created_at']),
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at']) 
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'mercado_pago_payment_id': mercadoPagoPaymentId,
      'amount': amount,
      'status': status,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
}