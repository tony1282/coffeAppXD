// lib/presentation/providers/sale_provider.dart

import 'package:flutter/foundation.dart';
import '../../core/error/error_handler.dart';
import '../../core/utils/logger.dart';
import '../../data/models/sale_model.dart';
import '../../data/services/api_service.dart';

class SaleProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Sale> _sales = [];
  bool isLoading = false;
  String? errorMsg;

  List<Sale> get sales => List.unmodifiable(_sales);

  // ── Filtros por estado ──────────────────────────────────────
  List<Sale> get completadas =>
      _sales.where((s) => s.estadoVenta == 'completada').toList();
  List<Sale> get pendientes =>
      _sales.where((s) => s.estadoVenta == 'pendiente').toList();
  List<Sale> get canceladas =>
      _sales.where((s) => s.estadoVenta == 'cancelada').toList();

  // ── Totales para corte de caja (RF22) ──────────────────────
  double get totalVentas =>
      completadas.fold(0.0, (s, v) => s + v.totalVenta);
  double get totalEfectivo =>
      completadas.fold(0.0, (s, v) => s + v.totalEfectivo);
  double get totalTarjeta =>
      completadas.fold(0.0, (s, v) => s + v.totalTarjeta);

  // ── Fetch ventas (RF21) ─────────────────────────────────────
  Future<void> fetchSales({String? periodo}) async {
    errorMsg = null;
    isLoading = true;
    notifyListeners();

    try {
      final endpoint =
          periodo != null ? '/sales/?periodo=$periodo' : '/sales/';
      final response = await _api.get(endpoint);

      if (response is! List) {
        _sales = [];
        notifyListeners();
        return;
      }

      final parsed = <Sale>[];
      for (final item in response) {
        if (item is! Map<String, dynamic>) continue;
        try {
          parsed.add(Sale.fromJson(item));
        } catch (_) {
          continue;
        }
      }
      _sales = parsed;
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
