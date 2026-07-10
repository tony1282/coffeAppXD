// lib/presentation/widgets/order/order_detail_bottom_sheet.dart

import 'package:coffe_app/data/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/ui/custom_dialogs.dart';
import '../../../presentation/providers/order_provider.dart';
import 'order_status_badge.dart';
import 'order_item_row.dart';
import 'order_progress_steps.dart';

class OrderDetailBottomSheet extends StatelessWidget {
  final int orderId;  // ← 🔥 CAMBIO: Recibir ID en lugar de todo el order

  const OrderDetailBottomSheet({
    super.key,
    required this.orderId,
  });

  // ✅ VERIFICAR SI EL PEDIDO ES CANCELABLE POR EL CLIENTE
  bool _isCancellable(String status) {
    return status == 'pending' || status == 'confirmed';
  }

  // ✅ FUNCIÓN PARA CANCELAR PEDIDO (CON REEMBOLSO AUTOMÁTICO)
  Future<void> _cancelOrder(BuildContext context, int orderId) async {
    final confirmed = await CustomDialogs.showConfirm(
      context: context,
      title: 'Cancelar pedido',
      message: '¿Estás seguro de cancelar el pedido #$orderId?\n\n'
               '⚠️ Si ya pagaste con tarjeta, se procesará un reembolso automático.',
      confirmText: 'Cancelar pedido',
      cancelText: 'No cancelar',
      confirmColor: AppColors.error,
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final provider = context.read<OrderProvider>();
    final success = await provider.cancelOrder(orderId);

    if (!context.mounted) return;

    if (success) {
      CustomDialogs.showSuccess(context, 'Pedido #$orderId cancelado');
      Navigator.pop(context); // Cerrar el bottom sheet
    } else {
      CustomDialogs.showError(
        context, 
        provider.errorMsg ?? 'Error al cancelar el pedido'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 NUEVO: ESCUCHAR CAMBIOS EN EL PROVIDER
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        // Buscar el pedido actualizado por ID
        final order = orderProvider.orders.cast<Order?>().firstWhere(
          (o) => o?.id == orderId,
          orElse: () => null,
        );

        // Si no hay pedido, mostrar loading
        if (order == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return _buildContent(context, order);
      },
    );
  }

  Widget _buildContent(BuildContext context, dynamic order) {
    final items = order.items ?? [];
    final double subtotal = order.total / 1.08;
    final double tax = order.total - subtotal;
    final status = order.status as String;
    final isCancellable = _isCancellable(status);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pedido #${order.id}',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OrderStatusBadge(status: status),
              ],
            ),
          ),

          // ── Progress steps ──
          OrderProgressSteps(status: status),

          const SizedBox(height: 4),

          // ── Scrollable body ──
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Delivery address box ──
                  if (order.deliveryAddress != null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.20),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ENTREGAR EN',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      order.deliveryAddress as String,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(
                            height: 1,
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: AppColors.textGrey,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tiempo estimado: 15 – 20 min',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Cambiar',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Products section header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tus productos',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${items.length} artículo${items.length == 1 ? '' : 's'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Items list ──
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.divider.withOpacity(0.8),
                    ),
                    itemBuilder: (context, index) =>
                        OrderItemRow(item: items[index]),
                  ),

                  // ── Order summary ──
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Subtotal',
                          value: '\$${subtotal.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Impuestos (8%)',
                          value: '\$${tax.toStringAsFixed(2)}',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(
                            height: 1,
                            color: AppColors.divider,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Payment method ──
                  if (order.paymentMethod != null)
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.credit_card_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Método de pago',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textGrey,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.paymentMethod as String,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textGrey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ✅ BOTÓN DE CANCELAR PARA CLIENTE (SOLO SI ES CANCELABLE)
                  if (isCancellable) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () => _cancelOrder(context, order.id),
                              icon: const Icon(Icons.cancel_outlined, size: 20),
                              label: const Text(
                                'Cancelar pedido',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                  color: AppColors.error.withOpacity(0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Si ya pagaste con tarjeta, se procesará un reembolso automático',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ✅ Mensaje si ya fue cancelado
                  if (status == 'cancelled') ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Este pedido fue cancelado',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGrey,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}