import 'package:coffe_app/widgets/admin/dashboard_kpi_card.dart';
import 'package:coffe_app/widgets/admin/dashboard_mini_stat.dart';
import 'package:coffe_app/widgets/admin/dashboard_order_tile.dart';
import 'package:coffe_app/widgets/admin/dashboard_product_admin_tile.dart';
import 'package:coffe_app/widgets/admin/dashboard_sales_bar_row.dart';
import 'package:coffe_app/widgets/admin/dashboard_section_header.dart';
import 'package:coffe_app/widgets/admin/dashboard_tab_bar.dart';
import 'package:coffe_app/widgets/admin/dashboard_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import 'products/admin_product_form.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Cargar datos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final orderProvider = context.read<OrderProvider>();
    final productProvider = context.read<ProductProvider>();

    await Future.wait([
      orderProvider.fetchOrders(),
      productProvider.fetchProducts(),
    ]);
  }

  void _switchTab(int i) {
    if (_tab == i) return;
    _fadeCtrl.reverse().then((_) {
      setState(() => _tab = i);
      _fadeCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const DashboardTopBar(),
            Consumer<OrderProvider>(
              builder: (context, orderProvider, _) {
                final pendingCount = orderProvider.orders
                    .where((o) => o.status == 'pendiente')
                    .length;
                return DashboardTabBar(
                  currentTab: _tab,
                  pendingCount: pendingCount,
                  onTap: _switchTab,
                );
              },
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0:
        return _buildResumen();
      case 1:
        return _buildPedidos();
      case 2:
        return _buildProductos();
      default:
        return _buildResumen();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 0 — RESUMEN
  // ══════════════════════════════════════════════════════════════
  Widget _buildResumen() {
    return Consumer2<OrderProvider, ProductProvider>(
      builder: (context, orderProvider, productProvider, _) {
        final orders = orderProvider.orders;
        final products = productProvider.products;

        final pendientes = orders.where((o) => o.status == 'pendiente').length;
        final preparando = orders.where((o) => o.status == 'preparando').length;
        final ingresos = orders.fold<double>(0, (s, o) => s + o.total);
        final maxSold = products.isNotEmpty
            ? products.map((p) => p.totalSold ?? 0).reduce((a, b) => a > b ? a : b)
            : 0;

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildKpiGrid(pendientes, preparando, ingresos, orders.length),
              const SizedBox(height: 26),
              _buildRecentOrders(orders),
              const SizedBox(height: 26),
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
              const Text(
                'Panel de control',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _today(),
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  Widget _buildKpiGrid(int pendientes, int preparando, double ingresos, int totalOrders) {
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

  Widget _buildRecentOrders(List<Order> orders) {
    return Column(
      children: [
        DashboardSectionHeader(
          title: 'Pedidos recientes',
          trailing: TextButton(
            onPressed: () => _switchTab(1),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Ver todos →',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...orders.take(4).map(
              (o) => DashboardOrderTile(
                order: o,
                onStatusChange: (newStatus) => _updateOrderStatus(o.id, newStatus),
              ),
            ),
      ],
    );
  }

  Widget _buildTopProducts(List<Product> products, int maxSold) {
    if (products.isEmpty) {
      return const Center(child: Text('No hay productos'));
    }

    return Column(
      children: [
        DashboardSectionHeader(
          title: 'Más vendidos',
          trailing: const Text(
            'unidades',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
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

  // ══════════════════════════════════════════════════════════════
  // TAB 1 — PEDIDOS
  // ══════════════════════════════════════════════════════════════
  Widget _buildPedidos() {
    final filtros = ['Todos', 'Pendiente', 'Preparando', 'Listo', 'Entregado'];

    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        return StatefulBuilder(
          builder: (context, setStatePedidos) {
            String filtroActual = 'Todos';

            final lista = filtroActual == 'Todos'
                ? orderProvider.orders
                : orderProvider.orders
                    .where((o) => o.status == filtroActual.toLowerCase())
                    .toList();

            return RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildFilterBar(filtros, filtroActual, setStatePedidos),
                  _buildOrderCounter(lista.length),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: lista
                          .map(
                            (o) => DashboardOrderTile(
                              order: o,
                              expanded: true,
                              onStatusChange: (newStatus) =>
                                  _updateOrderStatus(o.id, newStatus),
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
      },
    );
  }

  Widget _buildFilterBar(
    List<String> filtros,
    String filtroActual,
    StateSetter setStatePedidos,
  ) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filtros.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = filtroActual == filtros[i];
            return GestureDetector(
              onTap: () => setStatePedidos(() => filtroActual = filtros[i]),
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
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    filtros[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(int? orderId, String newStatus) async {
    if (orderId == null) return;
    await context.read<OrderProvider>().updateOrderStatus(orderId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido actualizado a ${_getStatusLabel(newStatus)}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getStatusLabel(String status) {
    const labels = {
      'pendiente': 'Pendiente',
      'preparando': 'Preparando',
      'listo': 'Listo',
      'entregado': 'Entregado',
    };
    return labels[status] ?? status;
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 2 — PRODUCTOS
  // ══════════════════════════════════════════════════════════════
  Widget _buildProductos() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final products = productProvider.products;
        final totalSold = products.fold<int>(0, (s, p) => s + (p.totalSold ?? 0));

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Row(
                children: [
                  DashboardMiniStat(
                    label: 'Productos',
                    value: '${products.length}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  DashboardMiniStat(
                    label: 'Total vendidos',
                    value: '$totalSold',
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAddProductButton(),
              const SizedBox(height: 20),
              const DashboardSectionHeader(title: 'Catálogo actual'),
              const SizedBox(height: 10),
              if (productProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (products.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No hay productos'),
                  ),
                )
              else
                ...products.map(
                  (p) => DashboardProductAdminTile(
                    product: p,
                    onEdit: () => _openForm(product: p),
                    onDelete: () => _confirmDelete(context, p),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddProductButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.80),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openForm(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Agregar producto',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────
  Future<void> _openForm({Product? product}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminProductForm(product: product),
      ),
    );
    if (result == true && mounted) {
      await _loadData();
      setState(() {});
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, Product product) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Eliminar producto?',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Se eliminará "${product.name}" permanentemente.',
          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await context.read<ProductProvider>().deleteProduct(product.id);
      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${product.name}" eliminado'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        await _loadData();
      }
    }
  }

  String _today() {
    const meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final now = DateTime.now();
    return '${now.day} de ${meses[now.month]} de ${now.year}';
  }
}