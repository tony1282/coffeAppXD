import '../../core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../data/models/sale_model.dart';
import '../../core/error/error_handler.dart';
import '../../data/services/api_service.dart';
// lib/presentation/providers/sale_provider.dart

class SaleProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Sale> _sales = [];
  bool isLoading = false;
  String? errorMsg;
  String _currentPeriodo = 'dia';

  List<Sale> get sales => List.unmodifiable(_sales);

  List<Sale> salesForPeriodo(String? periodo) =>
      _filterSalesByPeriodo(_sales, periodo ?? _currentPeriodo);

  // ── Filtros por estado ──────────────────────────────────────
  List<Sale> get completadas => salesForPeriodo(_currentPeriodo)
      .where((s) => s.estadoVenta == 'completada')
      .toList();
  List<Sale> get pendientes => salesForPeriodo(_currentPeriodo)
      .where((s) => s.estadoVenta == 'pendiente')
      .toList();
  List<Sale> get canceladas => salesForPeriodo(_currentPeriodo)
      .where((s) => s.estadoVenta == 'cancelada')
      .toList();

  // ── Totales para corte de caja (RF22) ──────────────────────
  double get totalVentas => completadas.fold(0.0, (s, v) => s + v.totalVenta);
  double get totalEfectivo =>
      completadas.fold(0.0, (s, v) => s + v.totalEfectivo);
  double get totalTarjeta =>
      completadas.fold(0.0, (s, v) => s + v.totalTarjeta);

  List<Sale> _parseSales(dynamic response) {
    if (response is! List) return [];

    final parsed = <Sale>[];
    for (final item in response) {
      if (item is! Map<String, dynamic>) continue;
      try {
        parsed.add(Sale.fromJson(item));
      } catch (_) {
        continue;
      }
    }
    return parsed;
  }

  List<Sale> _filterSalesByPeriodo(List<Sale> sales, String? periodo) {
    final target = (periodo ?? _currentPeriodo).toLowerCase();
    if (target.isEmpty || target == 'all') return sales;

    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    switch (target) {
      case 'dia':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day + 1);
        break;
      case 'semana':
        final firstDay = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(firstDay.year, firstDay.month, firstDay.day);
        end = start.add(const Duration(days: 7));
        break;
      case 'mes':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        break;
      default:
        return sales;
    }

    return sales.where((sale) {
      final fecha = sale.fechaVenta;
      return !fecha.isBefore(start) && fecha.isBefore(end);
    }).toList();
  }

  // ── Fetch ventas (RF21) ─────────────────────────────────────
  Future<void> fetchSales({String? periodo}) async {
    errorMsg = null;
    isLoading = true;
    _currentPeriodo = periodo ?? _currentPeriodo;
    notifyListeners();

    try {
      final endpoint = ApiConfig.salesPath(_currentPeriodo);
      final response = await _api.get(endpoint);
      _sales = _parseSales(response);
    } catch (e) {
      errorMsg = ErrorHandler.handleError(e).message;
      if (kDebugMode) AppLogger.error('SaleProvider.fetchSales', e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _sales = [];
    errorMsg = null;
    notifyListeners();
  }
}
