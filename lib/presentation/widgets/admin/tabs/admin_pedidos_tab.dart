// lib/presentation/widgets/admin/tabs/admin_pedidos_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/ui/custom_dialogs.dart';
import '../../../../presentation/providers/order_provider.dart';
import '../../../../presentation/widgets/admin/dashboard_order_tile.dart';
import '../../../screens/admin/orders/admin_order_detail.dart';

class AdminPedidosTab extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const AdminPedidosTab({
    super.key,
    required this.onRefresh,
  });

  @override
  State<AdminPedidosTab> createState() => _AdminPedidosTabState();
}

class _AdminPedidosTabState extends State<AdminPedidosTab> {
  String _filtroPedidos = 'Todos';

  final List<String> _filtros = [
    'Todos', 'Pendiente', 'Preparando', 'Listo', 'En camino', 'Entregado'
  ];

  static const Map<String, String> _filtroToStatus = {
    'Pendiente':  'pending',
    'Preparando': 'confirmed',
    'Listo':      'preparing',
    'En camino':  'shipped',
    'Entregado':  'delivered',
  };

  void _openOrderDetail(int? orderId) {
    if (orderId == null) {
      CustomDialogs.showError(context, 'Error: ID de pedido no disponible');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminOrderDetail(orderId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final lista = _filtroPedidos == 'Todos'
            ? orderProvider.orders
            : orderProvider.orders
                .where((o) => o.status == _filtroToStatus[_filtroPedidos])
                .toList();

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: AppColors.primary,
          child: Column(
            children: [
              _buildFilterBar(),
              _buildOrderCounter(lista.length),
              Expanded(
                child: lista.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: lista.length,
                        itemBuilder: (_, i) {
                          final o = lista[i];
                          return DashboardOrderTile(
                            order: o,
                            expanded: false,
                            onTap: () => _openOrderDetail(o.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filtros.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = _filtroPedidos == _filtros[i];
            return GestureDetector(
              onTap: () => setState(() => _filtroPedidos = _filtros[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.textGrey.withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    _filtros[i],
                    style: AppTextStyles.labelSmall.copyWith(
                      color: active ? Colors.white : AppColors.textGrey,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCounter(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            '$count pedido${count == 1 ? '' : 's'}',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textGrey),
          ),
          const Spacer(),
          Text(
            'Toca para ver detalle',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textGrey.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 48, color: AppColors.textGrey.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'No hay pedidos',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}