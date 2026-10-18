import 'package:flutter_test/flutter_test.dart';
import 'package:gtt_deviazioni/core/models/saved_journey.dart';

void main() {
  group('SavedJourneyPage & SavedCambioStep', () {
    test('serializza e deserializza correttamente un percorso con 2 cambi', () {
      final step1 = SavedCambioStep(
        id: 's1',
        title: 'Partenza',
        stopIds: const ['2852', '1234'],
        stopCodes: const {'2852': '40', '1234': '422'},
        stopNames: const {'2852': 'Porta Nuova', '1234': 'Giachino'},
        preferenzialeStopId: '2852',
        lineNames: const ['68', '9'],
        transferMinutes: 5,
        priorityOrder: const ['68', '9'],
      );

      final step2 = SavedCambioStep(
        id: 's2',
        title: '1° Cambio',
        stopIds: const ['1182'],
        stopCodes: const {'1182': '1182'},
        stopNames: const {'1182': 'Castello'},
        preferenzialeStopId: '1182',
        lineNames: const ['55', '13'],
        transferMinutes: 4,
        priorityOrder: const ['55', '13'],
      );

      final step3 = SavedCambioStep(
        id: 's3',
        title: '2° Cambio (Arrivo)',
        stopIds: const ['325'],
        stopCodes: const {'325': '325'},
        stopNames: const {'325': 'Bernini'},
        preferenzialeStopId: '325',
        lineNames: const ['M1S'],
        transferMinutes: 0,
        priorityOrder: const ['M1S'],
      );

      final journey = SavedJourneyPage(
        id: 'journey_test_1',
        name: 'Casa ➔ Ufficio',
        cambiCount: 2,
        steps: [step1, step2, step3],
        createdAt: DateTime(2026, 10, 15, 20, 0),
      );

      final json = journey.toJson();
      final roundtrip = SavedJourneyPage.fromJson(json);

      expect(roundtrip, isNotNull);
      expect(roundtrip!.id, equals('journey_test_1'));
      expect(roundtrip.name, equals('Casa ➔ Ufficio'));
      expect(roundtrip.cambiCount, equals(2));
      expect(roundtrip.steps.length, equals(3));

      // Verifica step 1
      final r1 = roundtrip.steps[0];
      expect(r1.title, equals('Partenza'));
      expect(r1.stopIds, contains('2852'));
      expect(r1.codeFor('2852'), equals('40'));
      expect(r1.nameFor('2852'), equals('Porta Nuova'));
      expect(r1.preferenzialeStopId, equals('2852'));
      expect(r1.lineNames, equals(['68', '9']));
      expect(r1.transferMinutes, equals(5));
      expect(r1.priorityOrder, equals(['68', '9']));

      // Verifica step 2
      final r2 = roundtrip.steps[1];
      expect(r2.title, equals('1° Cambio'));
      expect(r2.transferMinutes, equals(4));

      // Verifica step 3
      final r3 = roundtrip.steps[2];
      expect(r3.title, equals('2° Cambio (Arrivo)'));
      expect(r3.lineNames, equals(['M1S']));
    });

    test('supporta fino a 3 cambi (4 tratte) e fallback per campi opzionali', () {
      final step = SavedCambioStep(
        id: 's_simple',
        title: 'Tappa Semplice',
        stopIds: const ['999'],
        stopCodes: const {},
        stopNames: const {},
        lineNames: const ['10N'],
      );

      expect(step.codeFor('999'), equals('999'));
      expect(step.nameFor('999'), equals('Fermata 999'));
      expect(step.transferMinutes, equals(5));
      expect(step.preferenzialeStopId, isNull);

      final j = SavedJourneyPage(
        id: 'j3',
        name: 'Viaggio Lungo',
        cambiCount: 3,
        steps: [step, step, step, step],
        createdAt: DateTime.now(),
      );

      expect(j.cambiCount, equals(3));
      expect(j.steps.length, equals(4));
    });
  });
}
