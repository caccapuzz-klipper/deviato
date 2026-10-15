/// Modello per le pagine di salvataggio personalizzate con cambi multipli (fino a 3 cambi).
library;

/// Singola tappa / cambio di un percorso salvato.
class SavedCambioStep {
  const SavedCambioStep({
    required this.id,
    required this.title,
    required this.stopIds,
    required this.stopCodes,
    required this.stopNames,
    this.preferenzialeStopId,
    required this.lineNames,
    this.transferMinutes = 5,
    this.priorityOrder = const [],
  });

  /// Identificativo univoco della tappa.
  final String id;

  /// Titolo descrittivo (es. "Partenza", "1° Cambio", "2° Cambio").
  final String title;

  /// Id GTFS delle fermate monitorate per questo cambio (possono essere più di una, es. fermate vicine).
  final List<String> stopIds;

  /// Mappa stopId -> codice palina (es. '2852' -> '40').
  final Map<String, String> stopCodes;

  /// Mappa stopId -> nome leggibile della fermata.
  final Map<String, String> stopNames;

  /// Id della fermata preferenziale tra quelle selezionate, se impostata.
  final String? preferenzialeStopId;

  /// Elenco dei nomi/numeri di linea da visionare a queste fermate (es. ["55", "68", "9"]).
  final List<String> lineNames;

  /// Minuti stimati per raggiungere la fermata della tappa successiva.
  final int transferMinutes;

  /// Ordine di priorità personalizzato (linee o fermate) riordinabile dall'utente.
  final List<String> priorityOrder;

  /// Restituisce il codice palina per un dato stopId, o lo stopId stesso se assente.
  String codeFor(String stopId) => stopCodes[stopId] ?? stopId;

  /// Restituisce il nome leggibile per un dato stopId.
  String nameFor(String stopId) => stopNames[stopId] ?? 'Fermata $stopId';

  SavedCambioStep copyWith({
    String? id,
    String? title,
    List<String>? stopIds,
    Map<String, String>? stopCodes,
    Map<String, String>? stopNames,
    String? preferenzialeStopId,
    List<String>? lineNames,
    int? transferMinutes,
    List<String>? priorityOrder,
  }) {
    return SavedCambioStep(
      id: id ?? this.id,
      title: title ?? this.title,
      stopIds: stopIds ?? this.stopIds,
      stopCodes: stopCodes ?? this.stopCodes,
      stopNames: stopNames ?? this.stopNames,
      preferenzialeStopId: preferenzialeStopId ?? this.preferenzialeStopId,
      lineNames: lineNames ?? this.lineNames,
      transferMinutes: transferMinutes ?? this.transferMinutes,
      priorityOrder: priorityOrder ?? this.priorityOrder,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'stopIds': stopIds,
        'stopCodes': stopCodes,
        'stopNames': stopNames,
        if (preferenzialeStopId != null) 'preferenziale': preferenzialeStopId,
        'lineNames': lineNames,
        'transferMinutes': transferMinutes,
        'priorityOrder': priorityOrder,
      };

  static SavedCambioStep? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'] as String? ?? '';
    final title = raw['title'] as String? ?? '';
    final stopIds = (raw['stopIds'] as List?)?.cast<String>() ?? const [];

    final rawCodes = raw['stopCodes'];
    final stopCodes = <String, String>{};
    if (rawCodes is Map) {
      for (final e in rawCodes.entries) {
        stopCodes['${e.key}'] = '${e.value}';
      }
    }

    final rawNames = raw['stopNames'];
    final stopNames = <String, String>{};
    if (rawNames is Map) {
      for (final e in rawNames.entries) {
        stopNames['${e.key}'] = '${e.value}';
      }
    }

    final preferenziale = raw['preferenziale'] as String?;
    final lineNames = (raw['lineNames'] as List?)?.cast<String>() ?? const [];
    final transferMinutes = (raw['transferMinutes'] as num?)?.toInt() ?? 5;
    final priorityOrder =
        (raw['priorityOrder'] as List?)?.cast<String>() ?? const [];

    return SavedCambioStep(
      id: id,
      title: title,
      stopIds: stopIds,
      stopCodes: stopCodes,
      stopNames: stopNames,
      preferenzialeStopId: preferenziale,
      lineNames: lineNames,
      transferMinutes: transferMinutes,
      priorityOrder: priorityOrder,
    );
  }
}

/// Pagina di salvataggio personalizzata contenente fino a 3 cambi (fino a 4 tratte).
class SavedJourneyPage {
  const SavedJourneyPage({
    required this.id,
    required this.name,
    required this.cambiCount,
    required this.steps,
    required this.createdAt,
  });

  /// Identificativo univoco della pagina.
  final String id;

  /// Nome scelto dall'utente per ricordarla (es. "Casa ➔ Lavoro", "Università").
  final String name;

  /// Numero di cambi scelti (da 1 a 3 cambi).
  final int cambiCount;

  /// Tappe che compongono il percorso (lunghezza = cambiCount + 1, cioè Partenza + cambi).
  final List<SavedCambioStep> steps;

  /// Data creazione / modifica.
  final DateTime createdAt;

  SavedJourneyPage copyWith({
    String? id,
    String? name,
    int? cambiCount,
    List<SavedCambioStep>? steps,
    DateTime? createdAt,
  }) {
    return SavedJourneyPage(
      id: id ?? this.id,
      name: name ?? this.name,
      cambiCount: cambiCount ?? this.cambiCount,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'cambiCount': cambiCount,
        'steps': [for (final s in steps) s.toJson()],
        'createdAt': createdAt.toIso8601String(),
      };

  static SavedJourneyPage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'] as String? ?? '';
    final name = raw['name'] as String? ?? 'Percorso';
    final cambiCount = (raw['cambiCount'] as num?)?.toInt() ?? 1;

    final rawSteps = raw['steps'];
    final steps = <SavedCambioStep>[];
    if (rawSteps is List) {
      for (final s in rawSteps) {
        if (SavedCambioStep.fromJson(s) case final step?) {
          steps.add(step);
        }
      }
    }

    final dateStr = raw['createdAt'] as String?;
    final createdAt = dateStr != null
        ? DateTime.tryParse(dateStr) ?? DateTime.now()
        : DateTime.now();

    return SavedJourneyPage(
      id: id,
      name: name,
      cambiCount: cambiCount,
      steps: steps,
      createdAt: createdAt,
    );
  }
}
