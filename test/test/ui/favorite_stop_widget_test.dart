import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gtt_deviazioni/data/app_repository.dart';
import 'package:gtt_deviazioni/data/fonte_dati.dart';
import 'package:gtt_deviazioni/data/settings.dart';
import 'package:gtt_deviazioni/ui/favorite_stop_widget.dart';

class _FakeFonte implements FonteDati {
  @override
  Future<Map<String, dynamic>?> scarica(String percorso) async => null;

  @override
  Future<Map<String, dynamic>?> salvato(String percorso) async => null;
}

Future<AppRepository> repoWith(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  return AppRepository(await Settings.load(), fonte: _FakeFonte());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FavoriteWidgetStop', () {
    test('salvataggio, caricamento e cancellazione', () async {
      expect(await FavoriteWidgetStop.load(), isNull);
      expect(await FavoriteWidgetStop.isFavorite('1234'), isFalse);

      await FavoriteWidgetStop.save(
        id: '1234',
        name: 'Porta Nuova',
        code: '40',
        lines: ['4', '15'],
      );

      final loaded = await FavoriteWidgetStop.load();
      expect(loaded, isNotNull);
      expect(loaded!.id, '1234');
      expect(loaded.name, 'Porta Nuova');
      expect(loaded.code, '40');
      expect(loaded.lines, ['4', '15']);
      expect(await FavoriteWidgetStop.isFavorite('1234'), isTrue);
      expect(await FavoriteWidgetStop.isFavorite('9999', '40'), isTrue);
      expect(await FavoriteWidgetStop.isFavorite('9999', '99'), isFalse);

      await FavoriteWidgetStop.clear();
      expect(await FavoriteWidgetStop.load(), isNull);
      expect(await FavoriteWidgetStop.isFavorite('1234'), isFalse);
    });
  });

  group('FavoriteStopWidgetCard', () {
    testWidgets('senza fermata preferita non occupa spazio', (tester) async {
      final repo = await repoWith({});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteStopWidgetCard(repo: repo),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('WIDGET FERMATA PREFERITA'), findsNothing);
    });

    testWidgets('con fermata preferita mostra titolo e palina', (tester) async {
      final repo = await repoWith({});
      await FavoriteWidgetStop.save(
        id: '1234',
        name: 'Porta Nuova',
        code: '40',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteStopWidgetCard(repo: repo),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('WIDGET FERMATA PREFERITA'), findsOneWidget);
      expect(find.text('Porta Nuova'), findsOneWidget);
      expect(find.text('Palina 40'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });
  });
}
