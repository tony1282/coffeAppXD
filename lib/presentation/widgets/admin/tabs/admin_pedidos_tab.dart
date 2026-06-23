// lib/presentation/widgets/admin/tabs/admin_pedidos_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/ui/custom_dialogs.dart';
import '../../../../presentation/providers/order_provider.dart';
import '../../../../presentation/widgets/admin/dashboard_order_tile.dart';

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
  final Set<int> _updatingOrders = {};

  final List<String> _filtros = ['Todos', 'Pendiente', 'Preparando', 'Listo', 'En camino', 'Entregado'];

  static const Map<String, String> _estadosMap = {
    'pending': 'Pendiente',
    'confirmed': 'Preparando',
    'preparing': 'Listo',
    'shipped': 'En camino',
    'delivered': 'Entregado',
    'cancelled': 'Cancelado',
  };

  String _getStatusLabel(String status) {
    return _estadosMap[status] ?? status;
  }

  Future<void> _updateOrderStatus(int? orderId, String newStatus) async {
    print('🔍 [ADMIN] _updateOrderStatus: orderId=$orderId, newStatus="$newStatus"');
    
    // ✅ VALIDAR QUE orderId NO SEA NULL
    if (orderId == null) {
      print('❌ [ADMIN] orderId es null, ignorando');
      CustomDialogs.showError(context, 'Error: ID de pedido no encontrado');
      return;
    }
    
    if (_updatingOrders.contains(orderId)) return;

    _updatingOrders.add(orderId);

    try {
      print('🔍 [ADMIN] Llamando a updateOrderStatus...');
      await context.read<OrderProvider>().updateOrderStatus(orderId, newStatus);
      print('✅ [ADMIN] updateOrderStatus exitoso');
      
      if (mounted) {
        final label = _getStatusLabel(newStatus);
        CustomDialogs.showSuccess(context, 'Pedido actualizado a $label');
        // ✅ ACTUALIZAR LA LISTA LOCALMENTE (sin fetch completo)
        setState(() {});
      }
    } catch (e) {
      print('❌ [ADMIN] Error: $e');
      if (mounted) {
        CustomDialogs.showError(context, 'Error al actualizar el estado');
      }
    } finally {
      if (mounted) _updatingOrders.remove(orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final lista = _filtroPedidos == 'Todos'
            ? orderProvider.orders
            : orderProvider.orders
                .where((o) => o.status == _filtroPedidos.toLowerCase())
                .toList();

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: Column(
            children: [
              _buildFilterBar(),
              _buildOrderCounter(lista.length),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: lista
                      .map(
                        (o) => DashboardOrderTile(
                          order: o,
                          expanded: true,
                          onStatusChange: (newStatus) {
                            _updateOrderStatus(o.id, newStatus);
                          },
                        ),
                      )
                      .toList(),
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
            '$count pedidos',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}