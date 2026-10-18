import 'package:flutter/material.dart';

/// Da dove arrivano le immagini della cartina, e di che colore sono i
/// segni che ci stanno sopra.
///
/// Con la chiave di CARTO — `CARTO_KEY`, passata alla compilazione con
/// `--dart-define-from-file=chiavi.json` — si usano Positron e, col tema
/// scuro, Dark Matter: grigi sobri su cui il rosso della deviazione, le
/// fermate e i mezzi risaltano, e una cartina che al buio diventa scura.
/// Senza chiave si torna alle immagini standard di OpenStreetMap, sempre
/// chiare: l'app funziona lo stesso.
///
/// CARTO e' gratuita per uso non commerciale fino a 5 milioni di immagini
/// al mese. In tutti e due i casi l'attribuzione deve stare sulla mappa,
/// sempre visibile: CARTO la vuole «non nascosta dietro un tocco».
class Cartina {
  const Cartina._({required this.scura});

  factory Cartina.of(BuildContext context) => Cartina._(
        scura: carto && Theme.of(context).brightness == Brightness.dark,
      );

  static const _chiave = String.fromEnvironment('CARTO_KEY');

  /// C'e' la chiave di CARTO.
  static bool get carto => _chiave.isNotEmpty;

  /// La cartina e' scura. Solo con CARTO: quella di OpenStreetMap e'
  /// chiara anche col tema scuro, e i segni devono leggersi su quella.
  final bool scura;

  String get url => carto
      ? 'https://{s}.basemaps.cartocdn.com/'
          '${scura ? 'dark_all' : 'light_all'}/{z}/{x}/{y}{r}.png?key=$_chiave'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  List<String> get sottodomini =>
      carto ? const ['a', 'b', 'c', 'd'] : const <String>[];

  String get attribuzione => carto
      ? '© contributori di OpenStreetMap · © CARTO'
      : '© contributori di OpenStreetMap';

  // I segni. Sulla cartina chiara quelli di sempre; su quella scura toni
  // piu' chiari, o le due direzioni sparirebbero nel grigio delle strade.

  /// Le due direzioni: la linea del percorso normale, e il bordo e la
  /// freccia delle sue fermate.
  ///
  /// Blu e verde, pieni. Il grigio-azzurro di prima sulla cartina grigia
  /// sembrava una strada, e col verde acqua accanto si distingueva poco.
  /// Tutti e due lontani dal rosso della deviazione e dal viola del
  /// percorso visto sui mezzi; dove i colori non bastano (chi non
  /// distingue bene il rosso dal verde) c'e' la freccia nelle fermate.
  Color direzione(int i) => scura
      ? (i == 0 ? const Color(0xFF0A84FF) : const Color(0xFF30D158))
      : (i == 0 ? const Color(0xFF007AFF) : const Color(0xFF34C759));

  /// Spessore della linea del percorso normale (4.5 pt) e deviazione (5.5 pt)
  static const spessorePercorso = 4.5;
  static const spessoreDeviazione = 5.5;

  /// Il mezzo che fa quella direzione: pieno, col bordo bianco.
  Color mezzo(int? direzione) => switch (direzione) {
        0 => const Color(0xFF007AFF),
        1 => const Color(0xFF34C759),
        _ => const Color(0xFF8E8E93),
      };

  Color get deviazione => scura ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);

  Color get osservato => scura ? const Color(0xFFBF5AF2) : const Color(0xFFAF52DE);

  /// Fermata non servita, mezzo fuori percorso.
  Color get chiusa => scura ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);

  /// Il bordo della fermata toccata.
  Color get selezione => scura ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);

  /// Il bordo di una fermata senza un verso solo.
  Color get bordoFermata =>
      scura ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);

  /// Il fondo della scritta dell'attribuzione.
  Color get fondoAttribuzione => scura
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.white.withValues(alpha: 0.7);
}
