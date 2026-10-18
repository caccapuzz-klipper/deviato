import '../geo/projection.dart';
import '../pipeline/stop_search.dart';

/// Una fermata con la distanza calcolata rispetto alla posizione dell'utente.
class FermataConDistanza {
  const FermataConDistanza({
    required this.fermata,
    required this.distanzaMetri,
  });

  final FermataCercabile fermata;
  final double distanzaMetri;

  /// Stringa amichevole della distanza (es. "80 m", "650 m", "1,4 km").
  String get distanzaFormattata {
    if (distanzaMetri < 1000) {
      return '${distanzaMetri.round()} m';
    }
    final km = distanzaMetri / 1000.0;
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}

/// Logica per gli arrivi e per le fermate vicine.
class ArriviFermataHelper {
  const ArriviFermataHelper._();

  /// Trova le fermate più vicine a [userLat, userLon] entro [raggioMetri],
  /// ordinate per distanza crescente, al massimo [max].
  static List<FermataConDistanza> fermateVicine(
    IndiceFermate indice, {
    required double userLat,
    required double userLon,
    int max = 20,
    double raggioMetri = 1500,
  }) {
    if (!Projection.isPlausible(userLat, userLon)) return const [];

    final userPoint = Projection.toMeters(userLat, userLon);
    final lista = <FermataConDistanza>[];

    for (final f in indice.fermate) {
      final pos = f.stop.position;
      final stopPoint = Projection.toMeters(pos.lat, pos.lon);
      final dist = userPoint.distanceTo(stopPoint);
      if (dist <= raggioMetri) {
        lista.add(FermataConDistanza(fermata: f, distanzaMetri: dist));
      }
    }

    lista.sort((a, b) => a.distanzaMetri.compareTo(b.distanzaMetri));
    return lista.take(max).toList();
  }
}
