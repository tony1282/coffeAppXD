// lib/data/models/sale_model.dart

class Sale {
  final int? id;
  final DateTime fechaVenta;
  final double totalVenta;
  final double totalEfectivo;
  final double totalTarjeta;
  final List<dynamic> listaProductos;
  final List<dynamic> pedidosTotales;
  final String? idUsuario;
  final String estadoVenta;
  final String? periodoVenta;

  static const List<String> _validStatuses = [
    'completada', 'pendiente', 'cancelada',
  ];

  Sale({
    this.id,
    required this.fechaVenta,
    required this.totalVenta,
    required this.totalEfectivo,
    required this.totalTarjeta,
    required this.listaProductos,
    required this.pedidosTotales,
    this.idUsuario,
    required this.estadoVenta,
    this.periodoVenta,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    double _parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    final status = json['estado_venta']?.toString().toLowerCase() ?? 'pendiente';

    return Sale(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      fechaVenta: _parseDate(json['fecha_venta']),
      totalVenta: _parseDouble(json['total_venta']),
      totalEfectivo: _parseDouble(json['total_efectivo']),
      totalTarjeta: _parseDouble(json['total_tarjeta']),
      listaProductos: json['lista_productos'] is List ? json['lista_productos'] : [],
      pedidosTotales: json['pedidos_totales'] is List ? json['pedidos_totales'] : [],
      idUsuario: json['id_usuario']?.toString(),
      estadoVenta: _validStatuses.contains(status) ? status : 'pendiente',
      periodoVenta: json['periodo_venta']?.toString(),
    );
  }

  String get estadoTexto {
    switch (estadoVenta) {
      case 'completada': return 'Completada';
      case 'cancelada': return 'Cancelada';
      default: return 'Pendiente';
    }
  }
}
