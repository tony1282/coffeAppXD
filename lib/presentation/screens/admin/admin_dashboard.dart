import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/constants.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../presentation/providers/sale_provider.dart';
import '../../../presentation/providers/order_provider.dart';
import '../../../presentation/providers/product_provider.dart';
import '../../../presentation/widgets/admin/dashboard_tab_bar.dart';
import '../../../presentation/widgets/admin/tabs/admin_ventas_tab.dart';
import '../../../presentation/widgets/admin/tabs/admin_pedidos_tab.dart';
import '../../../presentation/widgets/admin/tabs/admin_resumen_tab.dart';
import '../../../presentation/widgets/admin/tabs/admin_productos_tab.dart';
// lib/presentation/screens/admin/admin_dashboard.dart

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Datos de navegación (solo diseño, misma lista de tabs) ──────
  static const List<String> _tabTitles = [
    'Resumen',
    'Pedidos',
    'Productos',
    'Ventas',
  ];

  static const List<IconData> _tabIcons = [
    Icons.dashboard_rounded,
    Icons.receipt_long_rounded,
    Icons.coffee_rounded,
    Icons.bar_chart_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    // Registrar SaleProvider si no está en el árbol
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        context.read<OrderProvider>().fetchOrders(),
        context.read<ProductProvider>().fetchProducts(),
        context.read<SaleProvider>().fetchSales(periodo: 'dia'),
      ]);
    } catch (e) {
      if (mounted) {
        CustomDialogs.showError(context, 'Error al cargar los datos');
      }
    }
  }

  Future<void> _loadSales() async {
    try {
      await context.read<SaleProvider>().fetchSales(periodo: 'dia');
    } catch (_) {}
  }

  void _switchTab(int index) {
    if (_currentTab == index) return;
    _fadeCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _currentTab = index);
        _fadeCtrl.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── Menú hamburguesa ──────────────────────────────────────
      drawer: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          final pendingCount =
              orderProvider.orders.where((o) => o.status == 'pending').length;
          return _AdminDrawer(
            currentTab: _currentTab,
            pendingCount: pendingCount,
            titles: _tabTitles,
            icons: _tabIcons,
            onSelect: (index) {
              Navigator.of(context).pop(); // cierra el drawer
              _switchTab(index);
            },
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: el botón de menú ahora vive dentro de
            // DashboardTopBar (en blanco, sobre el fondo azul) ──────
            Builder(
              builder: (context) {
                return DashboardTabBar(
                  onMenuPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),

            // ── Indicador de sección actual (chip pequeño, solo visual) ──
            Padding(
              padding: EdgeInsets.fromLTRB(isWide ? 28 : 20, 14, isWide ? 28 : 20, 4),
              child: Row(
                children: [
                  Icon(_tabIcons[_currentTab],
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    _tabTitles[_currentTab],
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: isWide ? 20 : 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildCurrentTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case 0:
        return AdminResumenTab(onRefresh: _loadData);
      case 1:
        return AdminPedidosTab(onRefresh: _loadData);
      case 2:
        return AdminProductosTab(onRefresh: _loadData);
      case 3:
        return AdminVentasTab(onRefresh: _loadSales);
      default:
        return AdminResumenTab(onRefresh: _loadData);
    }
  }
}

// ── Drawer del panel admin (solo diseño / navegación) ───────────────
class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.currentTab,
    required this.pendingCount,
    required this.titles,
    required this.icons,
    required this.onSelect,
  });

  final int currentTab;
  final int pendingCount;
  final List<String> titles;
  final List<IconData> icons;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.80),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.coffee_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panel Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Gestión del negocio',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Items de navegación
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: titles.length,
                itemBuilder: (context, index) {
                  final isSelected = index == currentTab;
                  final showBadge = index == 1 && pendingCount > 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onSelect(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(
                                icons[index],
                                size: 22,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textGrey,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  titles[index],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textDark,
                                  ),
                                ),
                              ),
                              if (showBadge)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$pendingCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              if (isSelected && !showBadge)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Pie del drawer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.textGrey.withOpacity(0.6)),
                  const SizedBox(width: 8),
                  Text(
                    'coffeApp · Panel administrativo',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
