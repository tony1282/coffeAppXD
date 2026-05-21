// lib/screens/admin/orders/admin_order_detail.dart

import 'package:coffe_app/widgets/order/order_detail_action_button.dart';
import 'package:coffe_app/widgets/order/order_detail_header.dart';
import 'package:coffe_app/widgets/order/order_detail_info_row.dart';
import 'package:coffe_app/widgets/order/order_detail_map.dart';
import 'package:coffe_app/widgets/order/order_detail_section.dart';
import 'package:coffe_app/widgets/order/order_detail_status_stopper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import '../../../config/order_status_config.dart';

// ── Local models ─────────────────────────────────────────────
class OrderItem {
  final String name;
  final int qty;
  final double price;
  double get subtotal => qty * price;
  OrderItem(this.name, this.qty, this.price);
}

class OrderDetail {
  final String id;
  final String clienteName;
  final String clientePhone;
  final String clienteAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final String paymentStatus;
  final String? mpTransactionId;
  final DateTime createdAt;
  final String status;
  final String? notes;

  double get total => subtotal + deliveryFee;

  OrderDetail({
    required this.id,
    required this.clienteName,
    required this.clientePhone,
    required this.clienteAddress,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.paymentStatus,
    this.mpTransactionId,
    required this.createdAt,
    required this.status,
    this.notes,
  });

  // ✅ copyWith para rollback seguro (evita mutación accidental)
  OrderDetail copyWith({String? status}) {
    return OrderDetail(
      id: id,
      clienteName: clienteName,
      clientePhone: clientePhone,
      clienteAddress: clienteAddress,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      paymentStatus: paymentStatus,
      mpTransactionId: mpTransactionId,
      createdAt: createdAt,
      status: status ?? this.status,
      notes: notes,
    );
  }
}

class AdminOrderDetail extends StatefulWidget {
  final OrderDetail? order;

  const AdminOrderDetail({super.key, this.order});

  @override
  State<AdminOrderDetail> createState() => _AdminOrderDetailState();
}

class _AdminOrderDetailState extends State<AdminOrderDetail> {
  late OrderDetail _order;
  bool _isProcessing = false; // ✅ Previene spam y actualizaciones múltiples

  static final _sample = OrderDetail(
    id: '002',
    clienteName: 'Luis Pérez',
    clientePhone: '+52 55 1234 5678',
    clienteAddress: 'Av. Insurgentes Sur 1234, Col. Del Valle, CDMX',
    items: [
      OrderItem('Cold Brew', 1, 65.00),
      OrderItem('Frappé Caramelo', 1, 75.00),
      OrderItem('Galleta de Avena', 2, 25.00),
    ],
    subtotal: 190.00,
    deliveryFee: 35.00,
    paymentStatus: 'pagado',
    mpTransactionId: 'MP-7823941023',
    createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    status: 'preparando',
    notes: 'Sin azúcar en el Cold Brew, por favor.',
  );

  @override
  void initState() {
    super.initState();
    _order = widget.order ?? _sample;
  }

  // ✅ Avanzar estado con confirmación + protección de spam
  Future<void> _advanceStatus() async {
    // Prevenir spam y operaciones durante actualización
    if (_isProcessing) return;

    final currentIdx = OrderStatusConfig.flow.indexOf(_order.status);
    if (currentIdx >= OrderStatusConfig.flow.length - 1) return;

    final nextStatus = OrderStatusConfig.flow[currentIdx + 1];
    final nextLabel = OrderStatusConfig.labels[nextStatus] ?? nextStatus;

    // Confirmación visual antes de avanzar (evita errores de admin)
    final confirmed = await _showConfirmDialog(
      title: 'Confirmar cambio de estado',
      message: '¿Marcar pedido como "$nextLabel"?',
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    // Guardar snapshot para rollback en caso de error
    final originalOrder = _order;

    // Optimistic update (mejora UX inmediata)
    setState(() {
      _order = _order.copyWith(status: nextStatus);
    });

    try {
      // TODO: Conectar con API real
      // await context.read<OrderProvider>().updateOrderStatus(_order.id, nextStatus);

      // Simulación de llamada a API (reemplazar con real)
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado actualizado correctamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Rollback en caso de error
      if (mounted) {
        setState(() {
          _order = originalOrder;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el estado'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ✅ Diálogo de confirmación reutilizable
  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(_order.createdAt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD (SIN CAMBIOS VISUALES)
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final statusIdx = OrderStatusConfig.flow.indexOf(_order.status);
    final isLast = statusIdx == OrderStatusConfig.flow.length - 1;
    final statusColor = OrderStatusConfig.colors[_order.status] ?? AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OrderDetailHeader(
              order: _order,
              timeAgo: _timeAgo(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  OrderDetailStatusStepper(currentStatus: _order.status),
                  const SizedBox(height: 20),
                  if (!isLast && !_isProcessing)
                    _buildAdvanceButton(statusColor, statusIdx),
                  if (!isLast && !_isProcessing) const SizedBox(height: 20),
                  OrderDetailMap(address: _order.clienteAddress),
                  const SizedBox(height: 20),
                  OrderDetailSection(
                    title: 'Cliente',
                    icon: Icons.person_rounded,
                    child: _buildClienteInfo(),
                  ),
                  const SizedBox(height: 14),
                  OrderDetailSection(
                    title: 'Productos',
                    icon: Icons.coffee_rounded,
                    child: _buildItems(),
                  ),
                  const SizedBox(height: 14),
                  OrderDetailSection(
                    title: 'Pago',
                    icon: Icons.payment_rounded,
                    child: _buildPayment(),
                  ),
                  if (_order.notes != null && _order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    OrderDetailSection(
                      title: 'Notas del cliente',
                      icon: Icons.sticky_note_2_rounded,
                      child: _buildNotes(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Botón avanzar (solo visual, sin cambios) ─────────────────────
  Widget _buildAdvanceButton(Color color, int idx) {
    final next = OrderStatusConfig.labels[OrderStatusConfig.flow[idx + 1]] ?? '';
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.80)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _advanceStatus, // ✅ ahora async con protección
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                OrderStatusConfig.icons[OrderStatusConfig.flow[idx + 1]],
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Marcar como $next',
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

  // ── Info cliente (sin cambios visuales) ──────────────────────────
  Widget _buildClienteInfo() {
    return Column(children: [
      OrderDetailInfoRow(
        icon: Icons.person_outline_rounded,
        label: 'Nombre',
        value: _order.clienteName,
      ),
      const OrderDetailInfoDivider(),
      OrderDetailInfoRow(
        icon: Icons.phone_outlined,
        label: 'Teléfono',
        value: _order.clientePhone,
        trailing: GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _order.clientePhone));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Teléfono copiado'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Copiar',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      const OrderDetailInfoDivider(),
      OrderDetailInfoRow(
        icon: Icons.location_on_outlined,
        label: 'Dirección',
        value: _order.clienteAddress,
        multiline: true,
      ),
    ]);
  }

  // ── Items (sin cambios visuales) ─────────────────────────────────
  Widget _buildItems() {
    return Column(
      children: _order.items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Column(children: [
          if (i > 0) const OrderDetailInfoDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${item.qty}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ]),
          ),
        ]);
      }).toList(),
    );
  }

  // ── Pago (sin cambios visuales) ──────────────────────────────────
  Widget _buildPayment() {
    final pColor = OrderStatusConfig.paymentColors[_order.paymentStatus] ?? AppColors.textGrey;
    final pLabel = OrderStatusConfig.paymentLabels[_order.paymentStatus] ?? '';
    final pIcon = OrderStatusConfig.paymentIcons[_order.paymentStatus] ?? Icons.payment_rounded;

    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: pColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pColor.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(pIcon, color: pColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pLabel,
                  style: TextStyle(
                    color: pColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_order.mpTransactionId != null)
                  Text(
                    'ID: ${_order.mpTransactionId}',
                    style: TextStyle(
                      color: pColor.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.textGrey.withOpacity(0.15)),
            ),
            child: const Text(
              'MP',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      const OrderDetailInfoDivider(),
      _PaymentRow(
        label: 'Subtotal',
        value: '\$${_order.subtotal.toStringAsFixed(2)}',
        highlight: false,
      ),
      const OrderDetailInfoDivider(),
      _PaymentRow(
        label: 'Envío',
        value: '\$${_order.deliveryFee.toStringAsFixed(2)}',
        highlight: false,
        badge: 'domicilio',
      ),
      const OrderDetailInfoDivider(),
      _PaymentRow(
        label: 'Total',
        value: '\$${_order.total.toStringAsFixed(2)}',
        highlight: true,
      ),
    ]);
  }

  // ── Notas (sin cambios visuales) ─────────────────────────────────
  Widget _buildNotes() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _order.notes!,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Acciones (sin cambios visuales) ──────────────────────────────
  Widget _buildActions() {
    return Row(children: [
      Expanded(
        child: OrderDetailActionButton(
          icon: Icons.phone_rounded,
          label: 'Llamar',
          color: AppColors.success,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Conecta url_launcher para llamadas'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OrderDetailActionButton(
          icon: Icons.copy_rounded,
          label: 'Copiar ID',
          color: AppColors.textGrey,
          onTap: () {
            Clipboard.setData(ClipboardData(text: '#${_order.id}'));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('ID copiado al portapapeles'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OrderDetailActionButton(
          icon: Icons.cancel_outlined,
          label: 'Cancelar',
          color: AppColors.error,
          onTap: _showCancelDialog,
        ),
      ),
    ]);
  }

  // ── Cancel dialog mejorado ────────────────────────────────────────
  Future<void> _showCancelDialog() async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Cancelar pedido?',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Se cancelará el pedido #${_order.id} de ${_order.clienteName}.',
          style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'No cancelar',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Cancelar pedido',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && !_isProcessing) {
      setState(() => _isProcessing = true);
      try {
        // TODO: llamar a tu servicio para cancelar
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.of(context).pop(true);
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }
}

// ── Fila de totales de pago (sin cambios visuales) ────────────────────
class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final String? badge;

  const _PaymentRow({
    required this.label,
    required this.value,
    required this.highlight,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: highlight ? 12 : 10),
      child: Row(children: [
        Text(
          label,
          style: TextStyle(
            color: highlight ? AppColors.textDark : AppColors.textGrey,
            fontSize: highlight ? 14 : 12,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.textGrey.withOpacity(0.10),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.warning : AppColors.textDark,
            fontSize: highlight ? 18 : 12,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: highlight ? -0.5 : 0,
          ),
        ),
      ]),
    );
  }
}