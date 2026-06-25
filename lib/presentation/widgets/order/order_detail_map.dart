// lib/presentation/widgets/order/order_detail_map.dart

import 'package:flutter/material.dart';
import '../../../core/config/constants.dart';
import '../../../core/theme/text_styles.dart';

class OrderDetailMap extends StatelessWidget {
  final String address;
  final double? lat;
  final double? lng;

  const OrderDetailMap({
    super.key,
    required this.address,
    this.lat,
    this.lng,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ CONVERTIR A DOUBLE CORRECTAMENTE
    final double parsedLat = lat != null ? lat!.toDouble() : 19.4326;
    final double parsedLng = lng != null ? lng!.toDouble() : -99.1332;

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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header sección
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 14),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Dirección de entrega',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1,
              color: AppColors.textGrey.withOpacity(0.10)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              address,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // ✅ FILA CORREGIDA (SIN DESBORDAMIENTO)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.textGrey,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Tiempo estimado: 15 - 20 min',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=$address';
                    // TODO: Implementar url_launcher
                  },
                  child: Text(
                    'Ver en mapa',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 140,
            width: double.infinity,
            color: AppColors.primary.withOpacity(0.04),
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 140),
                  painter: _MapGridPainter(),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.map_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lat != null && lng != null
                            ? '📍 Ubicación del cliente'
                            : 'Ubicación no disponible',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (lat != null && lng != null)
                        Text(
                          'Lat: ${parsedLat.toStringAsFixed(4)}, Lng: ${parsedLng.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: AppColors.textGrey.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.07)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}