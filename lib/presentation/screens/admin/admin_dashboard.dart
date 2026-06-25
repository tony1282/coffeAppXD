// lib/presentation/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/constants.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../presentation/providers/order_provider.dart';
import '../../../presentation/providers/product_provider.dart';
import '../../../presentation/widgets/admin/dashboard_tab_bar.dart';
import '../../../presentation/widgets/admin/dashboard_top_bar.dart';
import '../../../presentation/widgets/admin/tabs/admin_pedidos_tab.dart';
import '../../../presentation/widgets/admin/tabs/admin_productos_tab.dart';
import '../../../presentation/widgets/admin/tabs/admin_resumen_tab.dart';

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
      ]);
    } catch (e) {
      if (mounted) {
        CustomDialogs.showError(context, 'Error al cargar los datos');
      }
    }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const DashboardTopBar(),
            Consumer<OrderProvider>(
              builder: (context, orderProvider, _) {
                // ✅ FIX: usar 'pending' en inglés, no 'pendiente'
                final pendingCount = orderProvider.orders
                    .where((o) => o.status == 'pending')
                    .length;
                return DashboardTabBar(
                  currentTab: _currentTab,
                  pendingCount: pendingCount,
                  onTap: _switchTab,
                );
              },
            ),
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
      default:
        return AdminResumenTab(onRefresh: _loadData);
    }
  }
}