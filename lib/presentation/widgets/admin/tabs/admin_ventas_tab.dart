// lib/presentation/widgets/admin/tabs/admin_ventas_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/sale_model.dart';
import '../../../../presentation/providers/sale_provider.dart';

class AdminVentasTab extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const AdminVentasTab({super.key, required this.onRefresh});

  @override
  State<AdminVentasTab> createState() => _AdminVentasTabState();
}

class _AdminVentasTabState extends State<AdminVentasTab> {
  String _filtroEstado = 'Todas';
  String _filtroPeriodo = 'dia';

  static const _estadoFiltros = ['Todas', 'Completada', 'Pendiente', 'Cancelada'];
  static const _periodos = [
    ('dia', 'Hoy'),
    ('semana', 'Semana'),
    ('mes', 'Mes'),
  ];

  static const _estadoToKey = {
    'Completada': 'completada',
    'Pendiente': 'pendiente',
    'Cancelada': 'cancelada',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().fetchSales(periodo: _filtroPeriodo);
    });
  }

  Future<void> _onPeriodoChange(String periodo) async {
    setState(() => _filtroPeriodo = periodo);
    await context.read<SaleProvider>().fetchSales(periodo: periodo);
  }

  List<Sale> _filtered(List<Sale> sales) {
    if (_filtroEstado == 'Todas') return sales;
    final key = _estadoToKey[_filtroEstado];
    return sales.where((s) => s.estadoVenta == key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SaleProvider>(
      builder: (context, provider, _) {
        final filtered = _filtered(provider.sales);

        return RefreshIndicator(
          onRefresh: () async {
            await provider.fetchSales(periodo: _filtroPeriodo);
          },
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildPeriodoBar()),
              SliverToBoxAdapter(child: _buildCorteCaja(provider)),
              SliverToBoxAdapter(child: _buildEstadoBar()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    '${filtered.length} venta${filtered.length == 1 ? '' : 's'}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textGrey),
                  ),
                ),
              ),
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _SaleTile(sale: filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodoBar() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: _periodos.map((p) {
          final active = _filtroPeriodo == p.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onPeriodoChange(p.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.textGrey.withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    p.$2,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: active ? Colors.white : AppColors.textGrey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCorteCaja(SaleProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.point_of_sale_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Corte de caja',
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _CajaItem(
                label: 'Total ventas',
                value: Formatters.currency(provider.totalVentas),
                icon: Icons.attach_money_rounded,
              ),
              const SizedBox(width: 10),
              _CajaItem(
                label: 'Efectivo',
                value: Formatters.currency(provider.totalEfectivo),
                icon: Icons.payments_rounded,
              ),
              const SizedBox(width: 10),
              _CajaItem(
                label: 'Tarjeta',
                value: Formatters.currency(provider.totalTarjeta),
                icon: Icons.credit_card_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatChip(
                label: 'Completadas',
                count: provider.completadas.length,
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Pendientes',
                count: provider.pendientes.length,
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Canceladas',
                count: provider.canceladas.length,
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoBar() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      margin: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _estadoFiltros.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = _filtroEstado == _estadoFiltros[i];
            return GestureDetector(
              onTap: () => setState(() => _filtroEstado = _estadoFiltros[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                    _estadoFiltros[i],
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 48, color: AppColors.textGrey.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'No hay ventas en este período',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

// ── Tile de venta ──────────────────────────────────────────────────
class _SaleTile extends StatelessWidget {
  final Sale sale;
  const _SaleTile({required this.sale});

  Color _statusColor() {
    switch (sale.estadoVenta) {
      case 'completada':
        return AppColors.success;
      case 'cancelada':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor().withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_rounded,
                color: _statusColor(), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sale.id != null ? 'Venta #${sale.id}' : 'Venta',
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.currency(sale.totalVenta),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      Formatters.dateTime(sale.fechaVenta),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textGrey),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor().withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sale.estadoTexto,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _statusColor(),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (sale.listaProductos.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${sale.listaProductos.length} producto${sale.listaProductos.length == 1 ? '' : 's'} · '
                    'Efectivo: ${Formatters.currency(sale.totalEfectivo)} · '
                    'Tarjeta: ${Formatters.currency(sale.totalTarjeta)}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textGrey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────
class _CajaItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CajaItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
