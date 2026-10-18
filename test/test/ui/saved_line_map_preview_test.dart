import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtt_deviazioni/core/geo/projection.dart';
import 'package:gtt_deviazioni/core/models/transit.dart';
import 'package:gtt_deviazioni/core/pipeline/vehicle_watch.dart';
import 'package:gtt_deviazioni/core/sources/vehicles_source.dart';
import 'package:gtt_deviazioni/ui/saved_line_map_preview.dart';

void main() {
  const line = TransitLine(
    routeId: '4',
    shortName: '4',
    longName: 'Strada del Drosso - Falchera',
    routeType: 0,
  );

  testWidgets('mostra indicatore bus live e risponde al tocco', (tester) async {
    var opened = false;
    final track = VehicleTrack('3001')
      ..points.add(
        VehicleObservation(
          vehicleId: '3001',
          routeId: '4',
          position: const GeoPoint(45.07, 7.68),
          seenAt: DateTime.now(),
          bearing: 90,
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedLineMapPreview(
            line: line,
            status: null,
            vehicles: [track],
            onOpenMap: () => opened = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1 bus live'), findsOneWidget);
    expect(find.text('Espandi mappa'), findsOneWidget);

    await tester.tap(find.byType(SavedLineMapPreview));
    expect(opened, isTrue);
  });

  testWidgets('quando non ci sono bus mostra Nessun bus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedLineMapPreview(
            line: line,
            status: null,
            vehicles: const [],
            onOpenMap: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nessun bus'), findsOneWidget);
  });
}
