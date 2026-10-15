import 'package:html/parser.dart' as html_parser;

import '../config.dart';
import '../net/gtt_http.dart';

/// Uno sciopero dei trasporti proclamato sul portale ufficiale del MIT.
class Sciopero {
  const Sciopero({
    required this.inizio,
    required this.fine,
    required this.sindacati,
    required this.settore,
    required this.categoria,
    required this.modalita,
    required this.rilevanza,
    required this.note,
    this.riguardaGtt = true,
  });

  /// Data inizio sciopero.
  final DateTime inizio;

  /// Data fine sciopero.
  final DateTime fine;

  /// Sigle sindacali proclamanti (es. "CUB TRASPORTI/SGB").
  final String sindacati;

  /// Settore (es. "TPL", "Plurisettoriale", "Ferroviario").
  final String settore;

  /// Categoria di lavoratori (es. "Personale viaggiante", "Tutto il personale").
  final String categoria;

  /// Modalità / orari dello sciopero (es. "24 ore con rispetto fasce di garanzia").
  final String modalita;

  /// Rilevanza: "Nazionale", "Regionale", "Aziendale".
  final String rilevanza;

  /// Note aggiuntive (dettagli aziende, fasce, revoche).
  final String note;

  /// Vero se riguarda specificamente GTT o il TPL di Torino/Piemonte.
  final bool riguardaGtt;

  /// Verifica se lo sciopero è in corso oggi o previsto per domani rispetto a [oggi].
  bool isOggiODomani([DateTime? oggi]) {
    final now = oggi ?? DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfTomorrow = startOfToday.add(const Duration(days: 2));

    // Lo sciopero si sovrappone a oggi o domani se fine >= startOfToday e inizio < endOfTomorrow
    final startDay = DateTime(inizio.year, inizio.month, inizio.day);
    final endDay = DateTime(fine.year, fine.month, fine.day, 23, 59, 59);

    return endDay.isAfter(startOfToday) && startDay.isBefore(endOfTomorrow);
  }

  Map<String, dynamic> toJson() => {
        'inizio': inizio.toIso8601String(),
        'fine': fine.toIso8601String(),
        'sindacati': sindacati,
        'settore': settore,
        'categoria': categoria,
        'modalita': modalita,
        'rilevanza': rilevanza,
        'note': note,
        'riguardaGtt': riguardaGtt,
      };

  static Sciopero? fromJson(Map<String, dynamic> j) {
    try {
      final inizio = DateTime.parse(j['inizio'] as String);
      final fine = DateTime.parse(j['fine'] as String);
      return Sciopero(
        inizio: inizio,
        fine: fine,
        sindacati: (j['sindacati'] as String?) ?? '',
        settore: (j['settore'] as String?) ?? '',
        categoria: (j['categoria'] as String?) ?? '',
        modalita: (j['modalita'] as String?) ?? '',
        rilevanza: (j['rilevanza'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
        riguardaGtt: j['riguardaGtt'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'Sciopero $sindacati (${inizio.day}/${inizio.month} - ${fine.day}/${fine.month}): $modalita';
}

/// Lettura e parsing degli scioperi dal calendario del Ministero delle Infrastrutture e dei Trasporti.
class ScioperiMitSource {
  ScioperiMitSource({GttHttp? http}) : _http = http ?? GttHttp();

  final GttHttp _http;

  /// Scarica la pagina degli scioperi ed estrae quelli attinenti a Torino / GTT / TPL.
  Future<List<Sciopero>> fetchScioperi() async {
    final html = await _http.getText(
      GttConfig.scioperiMitUrl,
      timeout: const Duration(seconds: 15),
    );
    return parseHtml(html);
  }

  /// Parsa l'HTML della tabella ministeriale.
  List<Sciopero> parseHtml(String html) {
    if (html.trim().isEmpty) return const [];

    final document = html_parser.parse(html);
    final rows = document.querySelectorAll('table tr');
    if (rows.isEmpty) return const [];

    final list = <Sciopero>[];

    for (final tr in rows) {
      final cells = tr.querySelectorAll('td');
      // La tabella ha tipicamente 10 colonne:
      // [0] checkbox/vuoto, [1] Inizio, [2] Fine, [3] Sindacati, [4] Settore,
      // [5] Categoria, [6] Modalità, [7] Rilevanza, [8] Note, [9] Data proclamazione
      if (cells.length < 8) continue;

      final inizioStr = cells[1].text.trim();
      final fineStr = cells[2].text.trim();
      final sindacati = cells[3].text.trim();
      final settore = cells[4].text.trim();
      final categoria = cells[5].text.trim();
      final modalita = cells[6].text.trim();
      final rilevanza = cells[7].text.trim();
      final note = cells.length > 8 ? cells[8].text.trim() : '';

      final inizio = _parseDate(inizioStr);
      final fine = _parseDate(fineStr);
      if (inizio == null || fine == null) continue;

      // Filtro di pertinenza:
      // Cerchiamo esplicitamente 'GTT', 'TORINO', 'PIEMONTE', oppure
      // scioperi a rilevanza Nazionale del settore TPL/Trasporto Pubblico Locale.
      final fullText = '$sindacati $settore $categoria $modalita $rilevanza $note'.toUpperCase();

      final menzionaGtt = fullText.contains('GTT');
      final menzionaTorino = fullText.contains('TORINO') || fullText.contains('PIEMONTE');
      final isTpl = fullText.contains('TPL') || fullText.contains('TRASPORTO PUBBLICO LOCALE');
      final isNazionale = rilevanza.toUpperCase().contains('NAZIONALE');

      // Se non riguarda Torino, GTT o TPL Nazionale, scartiamo (es. scioperi di ferrovie in Calabria o aerei)
      if (!menzionaGtt && !menzionaTorino && !(isTpl && isNazionale)) {
        continue;
      }

      list.add(Sciopero(
        inizio: inizio,
        fine: fine,
        sindacati: sindacati,
        settore: settore,
        categoria: categoria,
        modalita: modalita,
        rilevanza: rilevanza,
        note: note,
        riguardaGtt: menzionaGtt || menzionaTorino,
      ));
    }

    // Ordina per data inizio
    list.sort((a, b) => a.inizio.compareTo(b.inizio));
    return list;
  }

  static DateTime? _parseDate(String str) {
    final clean = str.trim();
    final parts = clean.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }
}
