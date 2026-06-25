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

  Future<void> _cancelOrder() async {
    if (_isProcessing) return;

    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.currentOrder;
    if (order == null) return;

    if (order.status == 'delivered' || order.status == 'cancelled') {
      CustomDialogs.showError(context, 'Este pedido ya está finalizado');
      return;
    }

    // ✅ FIX: guardar el id ANTES de cualquier await
    final orderId = order.id!;

    final confirmed = await CustomDialogs.showConfirm(
      context: context,
      title: 'Cancelar pedido',
      message: '¿Cancelar el pedido #$orderId?\n\nSe devolverá el stock de los productos.',
      confirmText: 'Cancelar pedido',
      cancelText: 'No cancelar',
      confirmColor: AppColors.error,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    final success = await orderProvider.cancelOrder(orderId);

    if (mounted) {
      if (success) {
        CustomDialogs.showSuccess(context, 'Pedido #$orderId cancelado');
        // ✅ FIX: usar orderId guardado, no order.id
        await orderProvider.fetchOrderById(orderId);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        CustomDialogs.showError(context, 'Error al cancelar el pedido');
      }
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _advanceStatus() async {
    if (_isProcessing) return;

    final orderProvider = context.read<OrderProvider>();
    final order = orderProvider.currentOrder;
    if (order == null) return;

    if (order.status == 'cancelled' || order.status == 'delivered') {
      CustomDialogs.showError(context, 'Este pedido ya está finalizado');
      return;
    }

    final currentIdx = OrderStatusConfig.flow.indexOf(order.status);
    if (currentIdx >= OrderStatusConfig.flow.length - 1) return;

    // ✅ FIX: guardar todo lo necesario ANTES de cualquier await
    final orderId = order.id!;
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
    if (!mounted) return;

    setState(() => _isProcessing = true);

    final success = await orderProvider.updateOrderStatus(orderId, nextStatus);

    if (mounted) {
      if (success) {
        CustomDialogs.showSuccess(context, 'Pedido actualizado a $nextLabel');
        // ✅ FIX: el provider ya actualizó _currentOrder en updateOrderStatus
        // Solo refrescamos desde el backend para confirmar
        await orderProvider.fetchOrderById(orderId);
      } else {
        CustomDialogs.showError(context, 'Error al actualizar el estado');
      }
      setState(() => _isProcessing = false);
    }
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

            // ✅ FIX: mostrar loading solo si no hay orden cargada todavía
            // Si ya hay orden y solo estamos refrescando, no mostrar pantalla de carga
            if (isLoading && order == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
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
            final isCancelled = order.status == 'cancelled';
            final isDelivered = order.status == 'delivered';

            return Column(
              children: [
                OrderDetailHeader(order: order),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      OrderDetailStatusStepper(currentStatus: order.status),
                      const SizedBox(height: 20),

                      if (!isLast && !_isProcessing && !isCancelled && !isDelivered)
                        _buildAdvanceButton(statusIdx),
                      if (!isLast && !_isProcessing && !isCancelled && !isDelivered)
                        const SizedBox(height: 20),

                      OrderDetailMap(
                        address: order.deliveryAddress ?? 'Dirección no especificada',
                        lat: order.deliveryLat ?? 19.4326,
                        lng: order.deliveryLng ?? -99.1332,
                      ),
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
                      const SizedBox(height: 14),

                      if (order.notes != null && order.notes!.isNotEmpty) ...[
                        OrderDetailSection(
                          title: 'Notas del cliente',
                          icon: Icons.sticky_note_2_rounded,
                          child: AdminOrderNotes(order: order),
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (!isCancelled && !isDelivered) _buildCancelButton(),
                      const SizedBox(height: 20),
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

  Widget _buildCancelButton() {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _cancelOrder,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Text(
                'Cancelar pedido',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}