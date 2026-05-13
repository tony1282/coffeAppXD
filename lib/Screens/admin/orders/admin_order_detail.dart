// lib/screens/admin/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/../config/constants.dart';
// ════════════════════════════════════════════════════════════════
// MODELO  (reemplaza con tu modelo real de Order)
// ════════════════════════════════════════════════════════════════
class OrderDetail {
  final String          id;
  final String          clienteName;
  final String          clientePhone;
  final String          clienteAddress;
  final List<OrderItem> items;
  final double          subtotal;
  final double          deliveryFee;
  final String          paymentStatus; // 'pagado' | 'pendiente' | 'rechazado'
  final String?         mpTransactionId;
  final DateTime        createdAt;
  String                status; // 'pendiente'|'preparando'|'listo'|'en_camino'|'entregado'
  final String?         notes;

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

  double get total => subtotal + deliveryFee;
}

class OrderItem {
  final String name;
  final int    qty;
  final double unitPrice;
  OrderItem(this.name, this.qty, this.unitPrice);
  double get subtotal => qty * unitPrice;
}

// ════════════════════════════════════════════════════════════════
// SCREEN
// ════════════════════════════════════════════════════════════════
class OrderDetailScreen extends StatefulWidget {
  /// Pasa tu modelo real aquí. Por ahora usa datos de ejemplo.
  final OrderDetail? order;

  const OrderDetailScreen({super.key, this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderDetail _order;

  // ── Datos de ejemplo ─────────────────────────────────────────
  static final _sample = OrderDetail(
    id:              '002',
    clienteName:     'Luis Pérez',
    clientePhone:    '+52 55 1234 5678',
    clienteAddress:  'Av. Insurgentes Sur 1234, Col. Del Valle, CDMX',
    items: [
      OrderItem('Cold Brew',       1, 65.00),
      OrderItem('Frappé Caramelo', 1, 75.00),
      OrderItem('Galleta de Avena',2, 25.00),
    ],
    subtotal:        190.00,
    deliveryFee:     35.00,
    paymentStatus:   'pagado',
    mpTransactionId: 'MP-7823941023',
    createdAt:       DateTime.now().subtract(const Duration(minutes: 18)),
    status:          'preparando',
    notes:           'Sin azúcar en el Cold Brew, por favor.',
  );

  @override
  void initState() {
    super.initState();
    _order = widget.order ?? _sample;
  }

  // ── Status config ─────────────────────────────────────────────
  static const _statusFlow = [
    'pendiente', 'preparando', 'listo', 'en_camino', 'entregado',
  ];

  static const _statusLabels = {
    'pendiente':  'Pendiente',
    'preparando': 'Preparando',
    'listo':      'Listo',
    'en_camino':  'En camino',
    'entregado':  'Entregado',
  };

  static const _statusColors = {
    'pendiente':  AppColors.pending,
    'preparando': AppColors.preparing,
    'listo':      AppColors.ready,
    'en_camino':  AppColors.warning,
    'entregado':  AppColors.delivered,
  };

  static const _statusIcons = {
    'pendiente':  Icons.schedule_rounded,
    'preparando': Icons.local_fire_department_rounded,
    'listo':      Icons.check_circle_rounded,
    'en_camino':  Icons.delivery_dining_rounded,
    'entregado':  Icons.where_to_vote_rounded,
  };

  static const _paymentColors = {
    'pagado':    AppColors.success,
    'pendiente': AppColors.warning,
    'rechazado': AppColors.error,
  };

  static const _paymentLabels = {
    'pagado':    'Pago confirmado',
    'pendiente': 'Pago pendiente',
    'rechazado': 'Pago rechazado',
  };

  static const _paymentIcons = {
    'pagado':    Icons.verified_rounded,
    'pendiente': Icons.hourglass_top_rounded,
    'rechazado': Icons.cancel_rounded,
  };

  // ── Avanzar estado ────────────────────────────────────────────
  void _advanceStatus() {
    final idx = _statusFlow.indexOf(_order.status);
    if (idx < _statusFlow.length - 1) {
      setState(() => _order.status = _statusFlow[idx + 1]);
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(_order.createdAt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[_order.status] ?? AppColors.primary;
    final statusIdx   = _statusFlow.indexOf(_order.status);
    final isLast      = statusIdx == _statusFlow.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(statusColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [

                  // ── Stepper de estado ─────────────────────────
                  _buildStatusStepper(statusIdx),
                  const SizedBox(height: 20),

                  // ── Botón avanzar ─────────────────────────────
                  if (!isLast) _buildAdvanceButton(statusColor, statusIdx),
                  if (!isLast) const SizedBox(height: 20),

                  // ── Mapa placeholder ──────────────────────────
                  _buildMapPlaceholder(),
                  const SizedBox(height: 20),

                  // ── Info del cliente ──────────────────────────
                  _buildSection(
                    title: 'Cliente',
                    icon:  Icons.person_rounded,
                    child: _buildClienteInfo(),
                  ),
                  const SizedBox(height: 14),

                  // ── Items del pedido ──────────────────────────
                  _buildSection(
                    title: 'Productos',
                    icon:  Icons.coffee_rounded,
                    child: _buildItems(),
                  ),
                  const SizedBox(height: 14),

                  // ── Resumen de pago ───────────────────────────
                  _buildSection(
                    title: 'Pago',
                    icon:  Icons.payment_rounded,
                    child: _buildPayment(),
                  ),

                  // ── Notas ─────────────────────────────────────
                  if (_order.notes != null && _order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildSection(
                      title: 'Notas del cliente',
                      icon:  Icons.sticky_note_2_rounded,
                      child: _buildNotes(),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Acciones ──────────────────────────────────
                  _buildActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(Color statusColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 4),
        // Icono con color del status
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withOpacity(0.25)),
          ),
          child: Icon(
            _statusIcons[_order.status] ?? Icons.receipt_long_rounded,
            color: statusColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Pedido ',
                    style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Text('#${_order.id}',
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3)),
              ]),
              Text(_timeAgo(),
                  style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        // Badge status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.30)),
          ),
          child: Text(
            _statusLabels[_order.status] ?? _order.status,
            style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800),
          ),
        ),
      ]),
    );
  }

  // ── Stepper ───────────────────────────────────────────────────
  Widget _buildStatusStepper(int currentIdx) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 3, height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Progreso del pedido',
                style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              _statusFlow.length * 2 - 1,
              (i) {
                if (i.isOdd) {
                  final stepIdx = i ~/ 2;
                  final filled  = stepIdx < currentIdx;
                  final color   = _statusColors[_order.status] ?? AppColors.primary;
                  return Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: filled
                            ? color.withOpacity(0.5)
                            : AppColors.textGrey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }
                final stepIdx = i ~/ 2;
                final done    = stepIdx <= currentIdx;
                final active  = stepIdx == currentIdx;
                final color   = _statusColors[_order.status] ?? AppColors.primary;
                final stepColor = done ? color : AppColors.textGrey.withOpacity(0.3);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width:  active ? 32 : 24,
                      height: active ? 32 : 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? color.withOpacity(active ? 1 : 0.15)
                            : AppColors.textGrey.withOpacity(0.08),
                        border: active
                            ? Border.all(
                                color: color.withOpacity(0.35), width: 3)
                            : null,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _statusIcons[_statusFlow[stepIdx]],
                        size:  active ? 16 : 12,
                        color: active
                            ? Colors.white
                            : done
                                ? color
                                : AppColors.textGrey.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _statusLabels[_statusFlow[stepIdx]] ?? '',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: stepColor),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón avanzar ─────────────────────────────────────────────
  Widget _buildAdvanceButton(Color color, int idx) {
    final next = _statusLabels[_statusFlow[idx + 1]] ?? '';
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
          onTap: _advanceStatus,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_statusIcons[_statusFlow[idx + 1]],
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Marcar como $next',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mapa placeholder ──────────────────────────────────────────
  Widget _buildMapPlaceholder() {
    return Container(
      height: 190,
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
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Fondo simulando un mapa
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.04),
                  AppColors.primary.withOpacity(0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Grid de calles simulado
          CustomPaint(
            size: const Size(double.infinity, 190),
            painter: _MapGridPainter(),
          ),
          // Contenido centrado
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.map_rounded,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 10),
                const Text('Mapa en tiempo real',
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Mapbox — próximamente',
                    style: TextStyle(
                        color: AppColors.textGrey.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Badge dirección abajo
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.95),
                border: Border(
                  top: BorderSide(
                      color: AppColors.textGrey.withOpacity(0.10)),
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _order.clienteAddress,
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info cliente ──────────────────────────────────────────────
  Widget _buildClienteInfo() {
    return Column(children: [
      _InfoRow(
        icon:  Icons.person_outline_rounded,
        label: 'Nombre',
        value: _order.clienteName,
      ),
      _InfoDivider(),
      _InfoRow(
        icon:  Icons.phone_outlined,
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
                    borderRadius: BorderRadius.circular(10)),
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
            child: const Text('Copiar',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
      _InfoDivider(),
      _InfoRow(
        icon:  Icons.location_on_outlined,
        label: 'Dirección',
        value: _order.clienteAddress,
        multiline: true,
      ),
    ]);
  }

  // ── Items ─────────────────────────────────────────────────────
  Widget _buildItems() {
    return Column(
      children: [
        ..._order.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(children: [
            if (i > 0) _InfoDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${item.qty}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.name,
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                Text('\$${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          ]);
        }),
      ],
    );
  }

  // ── Pago ──────────────────────────────────────────────────────
  Widget _buildPayment() {
    final pColor = _paymentColors[_order.paymentStatus] ?? AppColors.textGrey;
    final pLabel = _paymentLabels[_order.paymentStatus] ?? '';
    final pIcon  = _paymentIcons[_order.paymentStatus]  ?? Icons.payment_rounded;

    return Column(children: [
      // Status de pago
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
                Text(pLabel,
                    style: TextStyle(
                        color: pColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
                if (_order.mpTransactionId != null)
                  Text('ID: ${_order.mpTransactionId}',
                      style: TextStyle(
                          color: pColor.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // Logo MP
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppColors.textGrey.withOpacity(0.15)),
            ),
            child: const Text('MP',
                style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      _InfoDivider(),
      // Subtotal
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        child: Row(children: [
          const Text('Subtotal',
              style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('\$${_order.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
      _InfoDivider(),
      // Envío
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        child: Row(children: [
          Row(children: [
            const Text('Envío',
                style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.textGrey.withOpacity(0.10),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text('domicilio',
                  style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const Spacer(),
          Text('\$${_order.deliveryFee.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
      _InfoDivider(),
      // Total
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Row(children: [
          const Text('Total',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('\$${_order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
        ]),
      ),
    ]);
  }

  // ── Notas ─────────────────────────────────────────────────────
  Widget _buildNotes() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _order.notes!,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Acciones ──────────────────────────────────────────────────
  Widget _buildActions() {
    return Row(children: [
      // Llamar al cliente
      Expanded(
        child: _ActionButton(
          icon:  Icons.phone_rounded,
          label: 'Llamar',
          color: AppColors.success,
          onTap: () {
            // launch('tel:${_order.clientePhone}');
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
      // Copiar ID de pedido
      Expanded(
        child: _ActionButton(
          icon:  Icons.copy_rounded,
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
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 10),
      // Cancelar pedido
      Expanded(
        child: _ActionButton(
          icon:  Icons.cancel_outlined,
          label: 'Cancelar',
          color: AppColors.error,
          onTap: () => _showCancelDialog(),
        ),
      ),
    ]);
  }

  // ── Cancel dialog ─────────────────────────────────────────────
  Future<void> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cancelar pedido?',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        content: Text(
          'Se cancelará el pedido #${_order.id} de ${_order.clienteName}.',
          style: const TextStyle(
              color: AppColors.textGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No cancelar',
                style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Cancelar pedido',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: llamar a tu servicio para cancelar
      Navigator.of(context).pop(true);
    }
  }

  // ── Section wrapper ───────────────────────────────────────────
  Widget _buildSection({
    required String  title,
    required IconData icon,
    required Widget  child,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(children: [
              Container(
                width: 3, height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: AppColors.primary, size: 14),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          child,
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.multiline = false,
  });
  final IconData icon;
  final String   label;
  final String   value;
  final Widget?  trailing;
  final bool     multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.textGrey.withOpacity(0.10),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Painter para simular el grid del mapa ─────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.07)
      ..strokeWidth = 1;

    // Líneas horizontales
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Líneas verticales
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}