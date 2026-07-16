import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/logger.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/order_provider.dart';
import '../../../presentation/widgets/order_history/order_card.dart';
import '../../../presentation/widgets/order_history/order_empty_state.dart';
import '../../../presentation/widgets/order_history/order_detail_bottom_sheet.dart';
// lib/presentation/screens/orders/order_history_screen.dart

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _activeFilter = 'Todos';

  // ✅ FILTROS COMPLETOS PARA EL CLIENTE
  static const _filters = [
    'Todos',
    'Pendiente',
    'Preparando',
    'Listo',
    'En camino',
    'Entregados',
  ];

  // ✅ MAPA DE FILTROS A ESTADOS INTERNOS (INGLÉS)
  static const _filterToStatus = {
    'Pendiente': 'pending',
    'Preparando': 'confirmed',
    'Listo': 'preparing',
    'En camino': 'shipped',
    'Entregados': 'delivered',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userModel?.userId;

    if (kDebugMode) AppLogger.debug('OrderHistoryScreen: userId = $userId');

    if (userId != null && userId.isNotEmpty) {
      await context.read<OrderProvider>().fetchOrders(userId: userId);
    } else if (mounted) {
      CustomDialogs.showError(
          context, 'Debes iniciar sesión para ver tus pedidos');
    }
  }

  Future<void> _refreshOrders() async {
    final userId = context.read<AuthProvider>().userModel?.userId;
    await context.read<OrderProvider>().fetchOrders(userId: userId);
  }

  void _showOrderDetail(dynamic order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => OrderDetailBottomSheet(orderId: order.id),
    );
  }

  List<dynamic> _filtered(List<dynamic> orders) {
    if (_activeFilter == 'Todos') return orders;
    final status = _filterToStatus[_activeFilter];
    return orders.where((o) => (o.status as String) == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          final orders = orderProvider.orders;
          final filtered = _filtered(orders);
          final isLoading = orderProvider.isLoading;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.card,
                elevation: 0,
                scrolledUnderElevation: 1,
                shadowColor: AppColors.border,
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis pedidos',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    if (orders.isNotEmpty)
                      Text(
                        '${orders.length} pedido${orders.length == 1 ? '' : 's'} recientes',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final filter = _filters[i];
                        final isActive = _activeFilter == filter;
                        return GestureDetector(
                          onTap: () => setState(() => _activeFilter = filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                filter,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textGrey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            body: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : filtered.isEmpty
                    ? const OrderEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshOrders,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            return OrderCard(
                              order: order,
                              onTap: () => _showOrderDetail(order),
                            );
                          },
                        ),
                      ),
          );
        },
      ),
    );
  }
}
