import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/deviation_service.dart';
import '../core/models/transit.dart';
import '../core/pipeline/vehicle_watch.dart';
import 'apple_theme.dart';
import 'cartina.dart';

/// Preview compatta della mappa per ogni linea salvata con posizioni dei bus live.
class SavedLineMapPreview extends StatelessWidget {
  const SavedLineMapPreview({
    required this.line,
    required this.status,
    required this.vehicles,
    required this.onOpenMap,
    this.loadingVehicles = false,
    this.onRefreshVehicles,
    this.height = 165,
    super.key,
  });

  final TransitLine line;
  final LineStatus? status;
  final List<VehicleTrack> vehicles;
  final VoidCallback onOpenMap;
  final bool loadingVehicles;
  final VoidCallback? onRefreshVehicles;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cartina = Cartina.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final shapes = status != null && status!.allShapes.isNotEmpty
        ? status!.allShapes
        : (status?.shape != null
            ? [status!.shape, if (status!.shapeReturn != null) status!.shapeReturn!]
            : const <RouteShape>[]);

    final deviations = status?.activeReports
            .where((r) => r.deviatedGeometry != null && r.deviatedGeometry!.isNotEmpty)
            .map(
              (r) => r.deviatedGeometry!
                  .map((p) => LatLng(p.lat, p.lon))
                  .toList(growable: false),
            )
            .toList() ??
        const <List<LatLng>>[];

    // Raccoglie tutti i punti per calcolare il bounding box dell'inquadratura
    final allPoints = <LatLng>[];
    for (final s in shapes) {
      for (final p in s.points) {
        allPoints.add(LatLng(p.lat, p.lon));
      }
    }
    for (final dev in deviations) {
      allPoints.addAll(dev);
    }
    for (final v in vehicles) {
      if (v.points.isNotEmpty) {
        final last = v.points.last.position;
        allPoints.add(LatLng(last.lat, last.lon));
      }
    }

    final bounds = (allPoints.length > 1 &&
            (allPoints.first.latitude != allPoints.last.latitude ||
                allPoints.first.longitude != allPoints.last.longitude))
        ? LatLngBounds.fromPoints(allPoints)
        : (allPoints.isNotEmpty
            ? LatLngBounds(
                LatLng(allPoints.first.latitude - 0.015, allPoints.first.longitude - 0.015),
                LatLng(allPoints.first.latitude + 0.015, allPoints.first.longitude + 0.015),
              )
            : LatLngBounds(
                const LatLng(45.03, 7.62),
                const LatLng(45.11, 7.74),
              ));

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppleColors.separator(context),
            width: AppleSizes.hairline,
          ),
        ),
        child: Stack(
          children: [
            // Mappa
            FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(14),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
                onTap: (_, _) => onOpenMap(),
              ),
              children: [
                TileLayer(
                  urlTemplate: cartina.url,
                  subdomains: cartina.sottodomini,
                  retinaMode: Cartina.carto && RetinaMode.isHighDensity(context),
                  userAgentPackageName: 'dev.tcdesign.deviato',
                ),
                // Tracciati del percorso
                PolylineLayer(
                  polylines: [
                    for (var i = 0; i < shapes.length; i++)
                      Polyline(
                        points: [
                          for (final p in shapes[i].points) LatLng(p.lat, p.lon),
                        ],
                        strokeWidth: 3.5,
                        color: cartina.direzione(i),
                      ),
                    for (final dev in deviations)
                      Polyline(
                        points: dev,
                        strokeWidth: 4.5,
                        color: cartina.deviazione,
                      ),
                  ],
                ),
                // Marker dei bus live
                if (vehicles.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      for (final t in vehicles)
                        if (t.points.isNotEmpty)
                          _buildVehicleMarker(context, t),
                    ],
                  ),
              ],
            ),

            // Tap detector overlay trasparente per aprire la mappa a schermo intero
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenMap,
                ),
              ),
            ),

            // Top-left: Attribuzione
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: cartina.fondoAttribuzione,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cartina.attribuzione,
                  style: TextStyle(
                    fontSize: 9,
                    color: cartina.scura ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),

            // Top-right: Badge bus live
            Positioned(
              top: 6,
              right: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppleSizes.radiusPill),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xCC1C1C1E)
                          : const Color(0xE6FFFFFF),
                      borderRadius: BorderRadius.circular(AppleSizes.radiusPill),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x33545458)
                            : const Color(0x26000000),
                        width: AppleSizes.hairline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loadingVehicles) ...[
                          const CupertinoActivityIndicator(radius: 5),
                          const SizedBox(width: 4),
                          Text(
                            'GPS…',
                            style: AppleTypography.caption2(context),
                          ),
                        ] else if (vehicles.isNotEmpty) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppleColors.systemGreen,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${vehicles.length} ${vehicles.length == 1 ? "bus live" : "bus live"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppleColors.systemGreen,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            CupertinoIcons.location_slash,
                            size: 10,
                            color: AppleColors.secondaryLabel(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Nessun bus',
                            style: AppleTypography.caption2(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom-right: Pulsante tocca per aprire mappa intera
            Positioned(
              bottom: 6,
              right: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppleSizes.radiusPill),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xCC1C1C1E)
                          : const Color(0xE6FFFFFF),
                      borderRadius: BorderRadius.circular(AppleSizes.radiusPill),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x33545458)
                            : const Color(0x26000000),
                        width: AppleSizes.hairline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          CupertinoIcons.map,
                          size: 11,
                          color: AppleColors.systemBlue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Espandi mappa',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppleColors.systemBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom-left: Indicatore deviazione attiva se presente
            if (status != null && status!.activeReports.isNotEmpty)
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppleColors.systemRed.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        size: 10,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Deviazione',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Marker _buildVehicleMarker(BuildContext context, VehicleTrack t) {
    final last = t.points.last;
    final pos = LatLng(last.position.lat, last.position.lon);
    final bearing = last.bearing;
    final isOffRoute = t.isOffRoute;

    return Marker(
      point: pos,
      width: 32,
      height: 32,
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isOffRoute ? AppleColors.systemRed : AppleColors.systemBlue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: (isOffRoute ? AppleColors.systemRed : AppleColors.systemBlue)
                    .withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: bearing != null
                ? Transform.rotate(
                    angle: bearing * math.pi / 180,
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 13,
                    ),
                  )
                : const Icon(
                    CupertinoIcons.bus,
                    color: Colors.white,
                    size: 13,
                  ),
          ),
        ),
      ),
    );
  }
}
