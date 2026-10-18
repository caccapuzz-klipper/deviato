import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtt_deviazioni/core/geo/projection.dart';
import 'package:gtt_deviazioni/core/models/transit.dart';
import 'package:gtt_deviazioni/core/pipeline/arrivi_fermata.dart';
import 'package:gtt_deviazioni/core/pipeline/stop_search.dart';
import 'package:gtt_deviazioni/core/sources/trip_updates_gtt.dart';

void main() {
  final fixtureJson = File('test/fixtures/transiti_palina_40.json');
  final fixturePb = File('test/fixtures/trip_update.pb');

  group('TripUpdatesGttSource - JSON Transiti Palina', () {
    test('parsa correttamente la fixture reale della fermata 40', () {
      final text = fixtureJson.readAsStringSync();
      final source = TripUpdatesGttSource();
      final arrivi = source.parseJsonTransiti(text, stopCode: '40');

      expect(arrivi.stopCode, equals('40'));
      expect(arrivi.isNotEmpty, isTrue);
      expect(arrivi.linee.length, equals(6));

      // Prima linea: 64 verso GRUGLIASCO, STAZIONE
      final l64 = arrivi.linee.firstWhere((l) => l.linea == '64');
      expect(l64.direzione, equals('GRUGLIASCO, STAZIONE'));
      expect(l64.direzioneBreve, equals('NAPOLI CAP'));
      expect(l64.avviso, isFalse);

      // Passaggi della 64: 19:40, 19:43, 20:02 (RT) + 20:25 (programmato)
      expect(l64.passaggi.length, greaterThanOrEqualTo(3));
      final rtPassaggi = l64.passaggi.where((p) => p.isRealtime).toList();
      final prPassaggi = l64.passaggi.where((p) => !p.isRealtime).toList();

      expect(rtPassaggi, isNotEmpty);
      expect(prPassaggi, isNotEmpty);
      expect(rtPassaggi.map((p) => p.orario), contains('19:41'));
      expect(rtPassaggi.map((p) => p.orario), contains('19:43'));
      expect(prPassaggi.map((p) => p.orario), contains('20:25'));
    });

    test('PassaggioArrivo calcola i minuti mancanti e le etichette', () {
      final p1 = const PassaggioArrivo(orario: '19:45', isRealtime: true);
      final rif1 = DateTime(2026, 10, 15, 19, 40); // mancano 5 minuti
      expect(p1.minutiMancanti(rif1), equals(5));
      expect(p1.etichettaTempo(rif1), equals('5 min'));

      final rifAdesso = DateTime(2026, 10, 15, 19, 45); // in arrivo
      expect(p1.minutiMancanti(rifAdesso), equals(0));
      expect(p1.etichettaTempo(rifAdesso), equals('Adesso'));

      final rifPassato = DateTime(2026, 10, 15, 19, 48); // passato da 3 min
      expect(p1.minutiMancanti(rifPassato), equals(-3));
      expect(p1.etichettaTempo(rifPassato), equals('Adesso'));

      final pLontano = const PassaggioArrivo(orario: '21:30', isRealtime: false);
      expect(pLontano.etichettaTempo(rif1), equals('21:30'));
    });

    test('gestisce risposte vuote o malformate senza andare in crash', () {
      final source = TripUpdatesGttSource();
      expect(source.parseJsonTransiti('', stopCode: '999').isEmpty, isTrue);
      expect(source.parseJsonTransiti('null', stopCode: '999').isEmpty, isTrue);
      expect(source.parseJsonTransiti('[]', stopCode: '999').isEmpty, isTrue);
      expect(source.parseJsonTransiti('{invalid', stopCode: '999').isEmpty, isTrue);
    });
  });

  group('TripUpdatesGttSource - Protobuf RT Feed', () {
    test('parsa correttamente il feed binario protobuf reale', () {
      final bytes = fixturePb.readAsBytesSync();
      final source = TripUpdatesGttSource();
      final feed = source.parseTripUpdatesProtobuf(bytes);

      expect(feed.entity.length, greaterThan(100));
      final prima = feed.entity.first;
      expect(prima.hasTripUpdate(), isTrue);
      expect(prima.tripUpdate.hasTrip(), isTrue);
      expect(prima.tripUpdate.trip.tripId.isNotEmpty, isTrue);
    });
  });

  group('ArriviFermataHelper - Fermate vicine', () {
    test('calcola la distanza e ordina per vicinanza', () {
      final fVicino = FermataCercabile(
        stop: const TransitStop(
          id: '1',
          code: '40',
          name: 'VITTORIO EMANUELE II',
          position: GeoPoint(45.0640, 7.6800),
        ),
        passaggi: const [(routeId: '68U', directionId: 0)],
      );

      final fLontano = FermataCercabile(
        stop: const TransitStop(
          id: '2',
          code: '900',
          name: 'SUPERGA',
          position: GeoPoint(45.0800, 7.7600), // ~6 km più a est
        ),
        passaggi: const [(routeId: '79U', directionId: 0)],
      );

      final indice = IndiceFermate(
        feed: 'test',
        fermate: [fLontano, fVicino],
        capolinea: const {},
      );

      final vicine = ArriviFermataHelper.fermateVicine(
        indice,
        userLat: 45.0641,
        userLon: 7.6802,
        raggioMetri: 1000,
      );

      expect(vicine.length, equals(1));
      expect(vicine.first.fermata.stop.code, equals('40'));
      expect(vicine.first.distanzaMetri, lessThan(100));
      expect(vicine.first.distanzaFormattata, endsWith('m'));
    });

    test('filtra coordinate non plausibili', () {
      final indice = IndiceFermate(
        feed: 'test',
        fermate: const [],
        capolinea: const {},
      );

      expect(
        ArriviFermataHelper.fermateVicine(
          indice,
          userLat: 0.0,
          userLon: 0.0, // Null Island
        ),
        isEmpty,
      );
    });
  });
}
