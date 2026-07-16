import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../../presentation/providers/order_provider.dart';
import '../../../../presentation/providers/product_provider.dart';
import '../../../../presentation/widgets/admin/dashboard_kpi_card.dart';
import '../../../../presentation/widgets/admin/dashboard_order_tile.dart';
import '../../../../presentation/widgets/admin/dashboard_sales_bar_row.dart';
import '../../../../presentation/widgets/admin/dashboard_section_header.dart';
// lib/presentation/screens/admin/tabs/admin_resumen_tab.dart

class AdminResumenTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const AdminResumenTab({
    super.key,
    required this.onRefresh,
  });

  bool _isSameDay(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _matchesPending(String status) {
    return status == 'pendiente' || status == 'pending';
  }

  bool _matchesPreparing(String status) {
    return status == 'preparando' ||
        status == 'preparing' ||
        status == 'confirmed';
  }

  String _today() {
    const meses = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final now = DateTime.now();
    return '${now.day} de ${meses[now.month]} de ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrderProvider, ProductProvider>(
      builder: (context, orderProvider, productProvider, _) {
        final orders = orderProvider.orders;
        final products = productProvider.products;
        final todayOrders =
            orders.where((o) => _isSameDay(o.createdAt)).toList();
        final historyOrders =
            orders.where((o) => !_isSameDay(o.createdAt)).toList();

        final pendientes =
            todayOrders.where((o) => _matchesPending(o.status)).length;
        final preparando =
            todayOrders.where((o) => _matchesPreparing(o.status)).length;
        final ingresos = todayOrders.fold<double>(0, (s, o) => s + o.total);
        final maxSold = products.isNotEmpty
            ? products
                .map((p) => p.totalSold ?? 0)
                .reduce((a, b) => a > b ? a : b)
            : 0;

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildHeroPanel(todayOrders.length, historyOrders.length),
              const SizedBox(height: 18),
              _buildKpiGrid(
                  pendientes, preparando, ingresos, todayOrders.length),
              const SizedBox(height: 24),
              _buildRecentOrders('Pedidos de hoy', todayOrders),
              const SizedBox(height: 20),
              _buildRecentOrders('Historial reciente', historyOrders),
              const SizedBox(height: 24),
              _buildTopProducts(products, maxSold),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel de control',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _today(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPanel(int todayCount, int historyCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen operativo',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'El panel muestra hoy de forma clara y deja el historial separado para revisar lo anterior.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textGrey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              _buildMiniStat('Hoy', '$todayCount', AppColors.primary),
              const SizedBox(height: 8),
              _buildMiniStat('Historial', '$historyCount', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.85),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
      int pendientes, int preparando, double ingresos, int totalOrders) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        DashboardKpiCard(
          icon: Icons.receipt_long_rounded,
          label: 'Pedidos hoy',
          value: '$totalOrders',
          color: AppColors.primary,
          sublabel: 'Total del día',
        ),
        DashboardKpiCard(
          icon: Icons.attach_money_rounded,
          label: 'Ingresos',
          value: '\$${ingresos.toStringAsFixed(0)}',
          color: AppColors.warning,
          sublabel: 'Total del día',
        ),
        DashboardKpiCard(
          icon: Icons.pending_actions_rounded,
          label: 'Pendientes',
          value: '$pendientes',
          color: AppColors.error,
          sublabel: 'Por atender',
        ),
        DashboardKpiCard(
          icon: Icons.local_fire_department_rounded,
          label: 'En preparación',
          value: '$preparando',
          color: AppColors.success,
          sublabel: 'En cocina',
        ),
      ],
    );
  }

  Widget _buildRecentOrders(String title, List<Order> orders) {
    return Column(
      children: [
        DashboardSectionHeader(title: title),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Sin pedidos en esta sección',
              style:
                  AppTextStyles.labelSmall.copyWith(color: AppColors.textGrey),
            ),
          )
        else
          ...orders.take(4).map(
                (o) => DashboardOrderTile(order: o),
              ),
      ],
    );
  }

  Widget _buildTopProducts(List<ProductModel> products, int maxSold) {
    if (products.isEmpty) {
      return const Center(child: Text('No hay productos'));
    }

    return Column(
      children: [
        DashboardSectionHeader(
          title: 'Más vendidos',
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: products
                .take(4)
                .map(
                  (p) => DashboardSalesBarRow(
                    productName: p.name,
                    sold: p.totalSold ?? 0,
                    maxSold: maxSold,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
