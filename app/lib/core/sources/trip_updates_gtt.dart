import 'dart:convert';
import 'dart:typed_data';

import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';

import '../config.dart';
import '../net/gtt_http.dart';

/// Un singolo passaggio di un mezzo alla fermata.
class PassaggioArrivo {
  const PassaggioArrivo({
    required this.orario,
    required this.isRealtime,
  });

  /// Orario in formato "HH:mm" (es. "19:40").
  final String orario;

  /// Vero se il passaggio è stimato in tempo reale via GPS/telemetria GTT;
  /// falso se si tratta dell'orario pianificato da orario statico.
  final bool isRealtime;

  /// Minuti mancanti rispetto a [oraRif].
  ///
  /// Restituisce la differenza in minuti:
  /// - <= 0: "in arrivo" / adesso
  /// - > 0: minuti attesi
  /// - null: se l'orario non è valido
  int? minutiMancanti(DateTime oraRif) {
    final parti = orario.split(':');
    if (parti.length < 2) return null;
    final h = int.tryParse(parti[0]);
    final m = int.tryParse(parti[1]);
    if (h == null || m == null) return null;

    var arrivo = DateTime(oraRif.year, oraRif.month, oraRif.day, h, m);
    // Se l'orario è già passato di oltre 2 ore (es. mezzanotte), può essere del giorno dopo
    if (arrivo.isBefore(oraRif.subtract(const Duration(hours: 2)))) {
      arrivo = arrivo.add(const Duration(days: 1));
    }
    return arrivo.difference(oraRif).inMinutes;
  }

  /// Descrizione breve dell'arrivo rispetto ad adesso.
  String etichettaTempo(DateTime oraRif) {
    final min = minutiMancanti(oraRif);
    if (min == null) return orario;
    if (min <= 0) return 'Adesso';
    if (min == 1) return '1 min';
    if (min <= 45) return '$min min';
    return orario;
  }

  @override
  String toString() => '$orario (${isRealtime ? "in tempo reale" : "programmato"})';
}

/// Tutti i passaggi previsti per una linea a una fermata.
class ArriviLinea {
  const ArriviLinea({
    required this.linea,
    this.lineaAlias,
    required this.direzione,
    this.direzioneBreve,
    this.avviso = false,
    required this.passaggi,
  });

  /// Nome visualizzato della linea (es. "64", "10N", "STAR 1").
  final String linea;
  final String? lineaAlias;

  /// Capolinea o direzione di marcia estesa.
  final String direzione;

  /// Direzione breve (es. "NAPOLI CAP").
  final String? direzioneBreve;

  /// Vero se GTT segnala un avviso attivo su questa linea.
  final bool avviso;

  /// Passaggi ordinati per orario.
  final List<PassaggioArrivo> passaggi;

  /// Il prossimo passaggio in assoluto, se presente.
  PassaggioArrivo? get prossimoPassaggio =>
      passaggi.isNotEmpty ? passaggi.first : null;

  @override
  String toString() => '$linea verso $direzione (${passaggi.length} passaggi)';
}

/// L'insieme di tutti i passaggi alle banchine di una fermata (palina).
class ArriviFermata {
  const ArriviFermata({
    required this.stopCode,
    this.stopId,
    required this.linee,
    required this.lettoIl,
  });

  /// Numero di palina (es. "40").
  final String stopCode;

  /// Id GTFS, se noto.
  final String? stopId;

  /// Le linee che transitano a questa palina con i loro passaggi.
  final List<ArriviLinea> linee;

  /// Quando è stata effettuata la lettura.
  final DateTime lettoIl;

  bool get isEmpty => linee.isEmpty;
  bool get isNotEmpty => linee.isNotEmpty;
}

/// Lettura degli arrivi in tempo reale e programmati per le fermate GTT.
class TripUpdatesGttSource {
  TripUpdatesGttSource({GttHttp? http}) : _http = http ?? GttHttp();

  final GttHttp _http;

  /// Scarica i transiti dal vivo per il numero di palina [palinaCode].
  Future<ArriviFermata> fetchArriviPalina(
    String palinaCode, {
    String? stopId,
  }) async {
    final url =
        '${GttConfig.transitiPalinaUrl}?palina=${Uri.encodeComponent(palinaCode)}&bacino=U&realtime=true&get_param=value';
    final jsonText = await _http.getText(url, timeout: const Duration(seconds: 10));
    return parseJsonTransiti(
      jsonText,
      stopCode: palinaCode,
      stopId: stopId,
      now: DateTime.now(),
    );
  }

  /// Parsa la risposta JSON dell'endpoint GTT CMS `palina.getTransitiOld`.
  ArriviFermata parseJsonTransiti(
    String jsonText, {
    required String stopCode,
    String? stopId,
    DateTime? now,
  }) {
    final lettoIl = now ?? DateTime.now();
    final pulito = jsonText.trim();
    if (pulito.isEmpty || pulito == 'null') {
      return ArriviFermata(
        stopCode: stopCode,
        stopId: stopId,
        linee: const [],
        lettoIl: lettoIl,
      );
    }

    final dynamic parsed;
    try {
      parsed = jsonDecode(pulito);
    } catch (_) {
      return ArriviFermata(
        stopCode: stopCode,
        stopId: stopId,
        linee: const [],
        lettoIl: lettoIl,
      );
    }

    if (parsed is! List) {
      return ArriviFermata(
        stopCode: stopCode,
        stopId: stopId,
        linee: const [],
        lettoIl: lettoIl,
      );
    }

    final linee = <ArriviLinea>[];
    for (final item in parsed) {
      if (item is! Map) continue;

      final linea = (item['Linea'] as String?)?.trim() ?? '';
      if (linea.isEmpty) continue;

      final lineaAlias = (item['LineaAlias'] as String?)?.trim();
      final direzione = (item['Direzione'] as String?)?.trim() ?? '';
      final direzioneBreve = (item['DirezioneBreve'] as String?)?.trim();
      final avviso = item['Avviso'] == true;

      // Realtime arrivals (PassaggiRT)
      final rtList = <String>[];
      final rawRt = item['PassaggiRT'];
      if (rawRt is List) {
        for (final r in rawRt) {
          if (r is String && r.trim().isNotEmpty) {
            rtList.add(r.trim());
          }
        }
      }

      // Planned arrivals (PassaggiPR or Passaggi)
      final prList = <String>[];
      final rawPr = item['PassaggiPR'];
      if (rawPr is List) {
        for (final p in rawPr) {
          if (p is String && p.trim().isNotEmpty) {
            prList.add(p.trim());
          }
        }
      } else if (item['Passaggi'] is String) {
        final rawString = item['Passaggi'] as String;
        for (final p in rawString.split(';')) {
          final trimmed = p.trim();
          if (trimmed.isNotEmpty) {
            prList.add(trimmed);
          }
        }
      }

      // Unione e dedublicazione:
      // I passaggi RT hanno priorità. Se un orario pianificato è già coperto
      // dal tempo reale, o vicino ad esso, mostriamo il tempo reale.
      final passaggi = <PassaggioArrivo>[];
      final visti = <String>{};

      for (final rt in rtList) {
        if (visti.add(rt)) {
          passaggi.add(PassaggioArrivo(orario: rt, isRealtime: true));
        }
      }
      for (final pr in prList) {
        if (visti.add(pr)) {
          passaggi.add(PassaggioArrivo(orario: pr, isRealtime: false));
        }
      }

      // Ordina i passaggi per orario crescente
      passaggi.sort((a, b) => a.orario.compareTo(b.orario));

      linee.add(ArriviLinea(
        linea: linea,
        lineaAlias: lineaAlias,
        direzione: direzione,
        direzioneBreve: direzioneBreve,
        avviso: avviso,
        passaggi: passaggi,
      ));
    }

    return ArriviFermata(
      stopCode: stopCode,
      stopId: stopId,
      linee: linee,
      lettoIl: lettoIl,
    );
  }

  /// Parsa il feed binario protobuf GTFS-Realtime `trip_update.aspx`.
  FeedMessage parseTripUpdatesProtobuf(Uint8List bytes) {
    return FeedMessage.fromBuffer(bytes);
  }
}
