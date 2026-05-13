class Payment {
  final int id;
  final int orderId;
  final double amount;
  final String method; // cash, card
  final String status; // pending, completed, failed
  final String? transactionId;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      orderId: json['order_id'],
      amount: json['amount'].toDouble(),
      method: json['method'],
      status: json['status'],
      transactionId: json['transaction_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}