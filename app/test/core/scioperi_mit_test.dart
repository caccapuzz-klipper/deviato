import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtt_deviazioni/core/sources/scioperi_mit.dart';

void main() {
  final fixtureHtml = File('test/fixtures/scioperi_mit.html');

  group('ScioperiMitSource', () {
    test('parsa correttamente la tabella reale dal portale MIT', () {
      final html = fixtureHtml.readAsStringSync();
      final source = ScioperiMitSource();
      final scioperi = source.parseHtml(html);

      expect(scioperi, isNotEmpty);

      // Trova lo sciopero che cita esplicitamente GTT
      final gtt = scioperi.where((s) => s.note.toUpperCase().contains('GTT')).toList();
      expect(gtt, isNotEmpty);

      final primoGtt = gtt.first;
      expect(primoGtt.inizio, equals(DateTime(2026, 11, 20)));
      expect(primoGtt.fine, equals(DateTime(2026, 11, 21)));
      expect(primoGtt.sindacati, contains('CUB TRASPORTI'));
      expect(primoGtt.riguardaGtt, isTrue);
      expect(primoGtt.rilevanza, equals('Nazionale'));
    });

    test('isOggiODomani rileva correttamente gli scioperi imminenti', () {
      final scioperoOggi = Sciopero(
        inizio: DateTime(2026, 10, 15),
        fine: DateTime(2026, 10, 15),
        sindacati: 'USB',
        settore: 'TPL',
        categoria: 'Viaggiante',
        modalita: '24 ore',
        rilevanza: 'Nazionale',
        note: 'Fasce garantite 6-9 e 18-21',
      );

      final scioperoDomani = Sciopero(
        inizio: DateTime(2026, 10, 16),
        fine: DateTime(2026, 10, 16),
        sindacati: 'COBAS',
        settore: 'TPL',
        categoria: 'Tutto il personale',
        modalita: '4 ore',
        rilevanza: 'Locale',
        note: '',
      );

      final scioperoTraUnaSettimana = Sciopero(
        inizio: DateTime(2026, 10, 25),
        fine: DateTime(2026, 10, 25),
        sindacati: 'FAISA',
        settore: 'TPL',
        categoria: 'Personale',
        modalita: '24 ore',
        rilevanza: 'Nazionale',
        note: '',
      );

      final oggi = DateTime(2026, 10, 15, 14, 0);

      expect(scioperoOggi.isOggiODomani(oggi), isTrue);
      expect(scioperoDomani.isOggiODomani(oggi), isTrue);
      expect(scioperoTraUnaSettimana.isOggiODomani(oggi), isFalse);
    });

    test('toJson e fromJson conservano tutte le informazioni', () {
      final s = Sciopero(
        inizio: DateTime(2026, 11, 20),
        fine: DateTime(2026, 11, 21),
        sindacati: 'CUB TRASPORTI',
        settore: 'TPL',
        categoria: 'Personale ferroviario',
        modalita: '24 ore',
        rilevanza: 'Nazionale',
        note: 'Dettagli GTT',
        riguardaGtt: true,
      );

      final json = s.toJson();
      final ricreato = Sciopero.fromJson(json);

      expect(ricreato, isNotNull);
      expect(ricreato!.inizio, equals(s.inizio));
      expect(ricreato.fine, equals(s.fine));
      expect(ricreato.sindacati, equals(s.sindacati));
      expect(ricreato.settore, equals(s.settore));
      expect(ricreato.riguardaGtt, equals(s.riguardaGtt));
    });
  });
}
