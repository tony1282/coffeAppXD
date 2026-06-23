// lib/presentation/screens/admin/orders/admin_order_detail.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/config/order_status_config.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/ui/custom_dialogs.dart';
import '../../../../presentation/providers/order_provider.dart';
import '../../../../presentation/widgets/admin/orders/admin_order_actions.dart';
import '../../../../presentation/widgets/admin/orders/admin_order_info.dart';
import '../../../../presentation/widgets/admin/orders/admin_order_items.dart';
import '../../../../presentation/widgets/admin/orders/admin_order_notes.dart';
import '../../../../presentation/widgets/admin/orders/admin_order_payment.dart';
import '../../../../presentation/widgets/order/order_detail_header.dart';
import '../../../../presentation/widgets/order/order_detail_map.dart';
import '../../../../presentation/widgets/order/order_detail_section.dart';
import '../../../../presentation/widgets/order/order_detail_status_stopper.dart';

class AdminOrderDetail extends StatefulWidget {
  final int? orderId;

  const AdminOrderDetail({super.key, this.orderId});

  @override
  State<AdminOrderDetail> createState() => _AdminOrderDetailState();
}

class _AdminOrderDetailState extends State<AdminOrderDetail> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OrderProvider>().fetchOrderById(widget.orderId!);
      });
    }
  }

  Future<void> _advanceStatus() async {
    if (_isProcessing) return;

    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.currentOrder;
    if (order == null) return;

    final currentIdx = OrderStatusConfig.flow.indexOf(order.status);
    if (currentIdx >= OrderStatusConfig.flow.length - 1) return;

    final nextStatus = OrderStatusConfig.flow[currentIdx + 1];
    final nextLabel = OrderStatusConfig.labels[nextStatus] ?? nextStatus;

    final confirmed = await CustomDialogs.showConfirm(
      context: context,
      title: 'Confirmar cambio de estado',
      message: '¿Marcar pedido como "$nextLabel"?',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      confirmColor: AppColors.primary,
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    final success = await orderProvider.updateOrderStatus(order.id!, nextStatus);

    if (mounted) {
      if (success) {
        CustomDialogs.showSuccess(context, 'Pedido actualizado a $nextLabel');
      } else {
        CustomDialogs.showError(context, 'Error al actualizar el estado');
      }
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, _) {
            final order = orderProvider.currentOrder;
            final isLoading = orderProvider.isLoading;

            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (order == null) {
              return Center(
                child: Text(
                  'Pedido no encontrado',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
              );
            }

            final statusIdx = OrderStatusConfig.flow.indexOf(order.status);
            final isLast = statusIdx == OrderStatusConfig.flow.length - 1;

            return Column(
              children: [
                OrderDetailHeader(order: order),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      OrderDetailStatusStepper(currentStatus: order.status),
                      const SizedBox(height: 20),
                      if (!isLast && !_isProcessing)
                        _buildAdvanceButton(statusIdx),
                      if (!isLast && !_isProcessing) const SizedBox(height: 20),
                      if (order.deliveryAddress != null)
                        OrderDetailMap(address: order.deliveryAddress!),
                      const SizedBox(height: 20),
                      OrderDetailSection(
                        title: 'Cliente',
                        icon: Icons.person_rounded,
                        child: AdminOrderInfo(order: order),
                      ),
                      const SizedBox(height: 14),
                      OrderDetailSection(
                        title: 'Productos',
                        icon: Icons.coffee_rounded,
                        child: AdminOrderItems(order: order),
                      ),
                      const SizedBox(height: 14),
                      OrderDetailSection(
                        title: 'Pago',
                        icon: Icons.payment_rounded,
                        child: AdminOrderPayment(order: order),
                      ),
                      if (order.notes != null && order.notes!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        OrderDetailSection(
                          title: 'Notas del cliente',
                          icon: Icons.sticky_note_2_rounded,
                          child: AdminOrderNotes(order: order),
                        ),
                      ],
                      const SizedBox(height: 20),
                      AdminOrderActions(order: order),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdvanceButton(int statusIdx) {
    final nextStatus = OrderStatusConfig.flow[statusIdx + 1];
    final nextLabel = OrderStatusConfig.labels[nextStatus] ?? nextStatus;
    final color = OrderStatusConfig.colors[nextStatus] ?? AppColors.primary;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.80)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _advanceStatus,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                OrderStatusConfig.icons[nextStatus],
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Marcar como $nextLabel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}