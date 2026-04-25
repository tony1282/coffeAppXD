import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  // ── Datos de ejemplo (reemplaza con tu Provider/Service) ────────
  final List<_Order> _orders = [
    _Order('001', 'Ana García',    ['Americano', 'Galleta'],  85.50,  'pendiente'),
    _Order('002', 'Luis Pérez',    ['Cold Brew', 'Frappé'],   134.00, 'preparando'),
    _Order('003', 'María López',   ['Capuchino x2'],           120.00, 'listo'),
    _Order('004', 'Carlos Ruiz',   ['Espresso', 'Avena'],      62.25,  'entregado'),
    _Order('005', 'Sofía Méndez',  ['Latte Helado'],           60.00,  'pendiente'),
    _Order('006', 'Jorge Torres',  ['Americano x3'],           165.00, 'preparando'),
  ];

  final List<_Product> _products = [
    _Product('Americano Clásico', 'Caliente',   55.00,  42),
    _Product('Cold Brew',         'Café frío',  65.00,  38),
    _Product('Capuchino',         'Caliente',   60.00,  31),
    _Product('Frappé Caramelo',   'Café frío',  75.00,  27),
    _Product('Galleta de Avena',  'Galletas',   25.00,  55),
    _Product('Espresso Doble',    'Caliente',   35.00,  20),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nombre = auth.userModel?.userName ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(nombre, auth),
            _buildTabBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────
  Widget _buildTopBar(String nombre, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(bottom: BorderSide(color: AppColors.textGrey)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.coffee_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('COFFEE SHOP',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.5)),
                Text('Hola, $nombre',
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 11)),
              ],
            ),
          ),
          // Badge admin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: const Text('ADMIN',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
          ),
          const SizedBox(width: 8),
          // Logout
          IconButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textGrey, size: 20),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
    );
  }

  // ── Tabs ─────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = [
      (Icons.dashboard_rounded,    'Resumen'),
      (Icons.receipt_long_rounded, 'Pedidos'),
      (Icons.coffee_rounded,       'Productos'),
    ];
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.textGrey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].$1,
                        size: 14,
                        color: active ? Colors.white : AppColors.textGrey),
                    const SizedBox(width: 5),
                    Text(tabs[i].$2,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.textGrey)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────
  Widget _buildBody() {
    switch (_tab) {
      case 0: return _buildResumen();
      case 1: return _buildPedidos();
      case 2: return _buildProductos();
      default: return _buildResumen();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 0 — RESUMEN
  // ═══════════════════════════════════════════════════════════════
  Widget _buildResumen() {
    final pendientes  = _orders.where((o) => o.status == 'pendiente').length;
    final preparando  = _orders.where((o) => o.status == 'preparando').length;
    final ingresos    = _orders.fold<double>(0, (s, o) => s + o.total);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Fecha ──────────────────────────────────────────────
        Row(children: [
          const Icon(Icons.calendar_today_rounded,
              size: 13, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Text(_today(),
              style: const TextStyle(
                  color: AppColors.textGrey, fontSize: 12)),
        ]),
        const SizedBox(height: 16),

        // ── KPIs ───────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _KpiCard(
              icon: Icons.receipt_long_rounded,
              label: 'Pedidos hoy',
              value: '${_orders.length}',
              color: AppColors.primary,
            ),
            _KpiCard(
              icon: Icons.attach_money_rounded,
              label: 'Ingresos',
              value: '\$${ingresos.toStringAsFixed(0)}',
              color: AppColors.warning,
            ),
            _KpiCard(
              icon: Icons.pending_actions_rounded,
              label: 'Pendientes',
              value: '$pendientes',
              color: AppColors.error,
            ),
            _KpiCard(
              icon: Icons.local_fire_department_rounded,
              label: 'En preparación',
              value: '$preparando',
              color: AppColors.success,
            ),
          ],
        ),

        const SizedBox(height: 22),

        // ── Pedidos recientes ───────────────────────────────────
        const _SectionTitle('Pedidos recientes'),
        const SizedBox(height: 10),
        ..._orders.take(4).map((o) => _OrderTile(order: o,
            onStatusChange: (s) => setState(() => o.status = s))),

        const SizedBox(height: 22),

        // ── Productos más vendidos ──────────────────────────────
        const _SectionTitle('Más vendidos hoy'),
        const SizedBox(height: 10),
        ..._products.take(3).map((p) => _ProductMiniTile(product: p)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 1 — PEDIDOS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPedidos() {
    final filtros = ['Todos', 'Pendiente', 'Preparando', 'Listo', 'Entregado'];
    return StatefulBuilder(
      builder: (ctx, setSt) {
        String filtro = 'Todos';
        return StatefulBuilder(builder: (ctx2, setSt2) {
          final lista = filtro == 'Todos'
              ? _orders
              : _orders.where(
                  (o) => o.status == filtro.toLowerCase()).toList();
          return Column(
            children: [
              // Filtros
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: filtros.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final active = filtro == filtros[i];
                    return GestureDetector(
                      onTap: () => setSt2(() => filtro = filtros[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: active ? AppColors.primary : AppColors.textGrey.withOpacity(0.3)),
                        ),
                        child: Text(filtros[i],
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : AppColors.textGrey)),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: lista
                      .map((o) => _OrderTile(
                            order: o,
                            expanded: true,
                            onStatusChange: (s) =>
                                setState(() => o.status = s),
                          ))
                      .toList(),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 2 — PRODUCTOS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildProductos() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Botón agregar
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigator.pushNamed(context, '/admin/producto/nuevo');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Agregar producto — conecta tu ruta'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Agregar producto',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._products.map((p) => _ProductAdminTile(product: p)),
      ],
    );
  }

  String _today() {
    const meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final now = DateTime.now();
    return '${now.day} de ${meses[now.month]} de ${now.year}';
  }
}

// ════════════════════════════════════════════════════════════════════
// MODELOS locales de ejemplo
// ════════════════════════════════════════════════════════════════════
class _Order {
  final String       id;
  final String       cliente;
  final List<String> items;
  final double       total;
  String             status;
  _Order(this.id, this.cliente, this.items, this.total, this.status);
}

class _Product {
  final String name;
  final String category;
  final double price;
  final int    sold;
  _Product(this.name, this.category, this.price, this.sold);
}

// ════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ════════════════════════════════════════════════════════════════════

// ── Título de sección ──────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3));
}

// ── KPI Card ──────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Order Tile ────────────────────────────────────────────────────
class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.onStatusChange,
    this.expanded = false,
  });
  final _Order  order;
  final bool    expanded;
  final void Function(String) onStatusChange;

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      'pendiente':  AppColors.pending,
      'preparando': AppColors.preparing,
      'listo':      AppColors.ready,
      'entregado':  AppColors.delivered,
    };
    final color = statusColors[order.status] ?? AppColors.textGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Número
            Text('#${order.id}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(order.cliente,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            // Total
            Text('\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          // Items
          Text(order.items.join(' · '),
              style: const TextStyle(
                  color: AppColors.textGrey, fontSize: 11)),
          const SizedBox(height: 10),
          Row(children: [
            // Badge status
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                order.status[0].toUpperCase() +
                    order.status.substring(1),
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            // Acción rápida
            if (order.status != 'entregado')
              GestureDetector(
                onTap: () {
                  const next = {
                    'pendiente':  'preparando',
                    'preparando': 'listo',
                    'listo':      'entregado',
                  };
                  onStatusChange(next[order.status] ?? order.status);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: const Text('Actualizar estado',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ],
      ),
    );
  }
}

// ── Mini tile productos (resumen) ─────────────────────────────────
class _ProductMiniTile extends StatelessWidget {
  const _ProductMiniTile({required this.product});
  final _Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(children: [
        Icon(Icons.coffee_rounded, color: AppColors.primary, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(product.name,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        Text('${product.sold} vendidos',
            style: const TextStyle(
                color: AppColors.textGrey, fontSize: 11)),
      ]),
    );
  }
}

// ── Producto admin tile ───────────────────────────────────────────
class _ProductAdminTile extends StatelessWidget {
  const _ProductAdminTile({required this.product});
  final _Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Icono
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.coffee_rounded,
              color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Row(children: [
                _Tag(product.category),
                const SizedBox(width: 6),
                Text('${product.sold} vendidos',
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 10)),
              ]),
            ],
          ),
        ),
        // Precio + acciones
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(children: [
              _IconBtn(Icons.edit_rounded,    AppColors.textGrey, () {}),
              const SizedBox(width: 4),
              _IconBtn(Icons.delete_rounded,  AppColors.error,   () {}),
            ]),
          ],
        ),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.textGrey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 9,
                fontWeight: FontWeight.w600)),
      );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn(this.icon, this.color, this.onTap);
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 13),
        ),
      );
}