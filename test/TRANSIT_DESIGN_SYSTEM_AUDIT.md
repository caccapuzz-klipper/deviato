# Transit Design System Audit & Implementation Report

Questo documento documenta l'applicazione e l'adattamento accurato del **Transit Design System** all'interno dell'applicazione DeviaTO nella cartella `test/`.

---

## 1. Obiettivo e Perimetro

- **Target**: Applicare l'estetica, i token visivi, i componenti e le convenzioni di design di **Transit** (`Transit_Design_System/`) all'app completa situata in `test/`.
- **Perimetro funzionale**: Esclusivamente le funzioni già decise e implementate finora. Nessuna rimozione di feature, nessun debordamento di scope ("scope creep").
- **Integrità architetturale**:
  - `app/` (produzione su branch `ui-apple`) resta intatta e non toccata.
  - La logica di business (`lib/core/`, pipeline GTFS-RT, modelli, calcoli, repository) è rimasta invariata.
  - Tutte le modifiche sono state confinate all'interfaccia utente (`lib/ui/`) e al sistema di temi.
  - Tutti i test esistenti (`flutter test`) e l'analisi statica (`flutter analyze`) sono rigorosamente verdi.

---

## 2. Design Tokens di Transit (`lib/ui/transit_theme.dart`)

### Colori Semantici e Superfici
- **Brand Green**: `#02B875` (Verde distintivo Transit per azioni primarie, selezione e identità).
- **Live Vibrant Green**: `#00C853` (Verde pulsante per segnali GPS in tempo reale).
- **OLED Pure Black**: `#010101` (Sfondo profondo per la modalità scura per massimizzare il contrasto e il risparmio energetico).
- **Pure White**: `#FEFEFE` / `#FFFFFF` (Sfondo pulito per la modalità chiara e testo ad altissimo contrasto).
- **Superfici Dark**: `#1C1C1E` (superficie elevata), `#2C2C2E` (superficie secondaria / raggruppata).
- **Superfici Light**: `#FFFFFF` (card), `#F2F2F7` (sfondo raggruppato).
- **Stato di Servizio**:
  - Regolare: `#34C759`
  - In programma / Attenzione: `#FFA000` / `#FF9500`
  - Chiusa / Deviata: `#FF3B30`
- **Royale Transit**:
  - Purple: `#6C3CE9`
  - Gold: `#FFC107`

### Contrasto Dinamico GTFS Route Badge
Implementazione precisa della formula fotometrica W3C WCAG:
$$L = 0.2126 \cdot R + 0.7152 \cdot G + 0.0722 \cdot B$$
Se il rapporto di contrasto con il bianco è $\ge 4.5:1$, viene utilizzato il testo bianco; altrimenti viene selezionato il nero profondo per garantire la massima leggibilità a colpo d'occhio.

### Tipografia
- Cifre tabulari (`fontFeatures: [FontFeature.tabularFigures()]`) per tutti i countdown di arrivo ed ETA per prevenire sfarfallii durante l'aggiornamento numerico al secondo.
- Titoli e badge: pesi `w700` / `w800` per il glanceable tracking.
- Dimensioni:
  - Grandi arrivi (Hero Countdown): 38-44 pt.
  - Route Badge: 20-22 pt bold.
  - Direction Header: 17 pt semibold.
  - Micro-badge e orari: 13-14 pt.

### Geometria e Forme (Squircle)
- Raggio Card: `16 pt` (`TransitSizes.cardRadius`).
- Raggio Badge Linea: `8 pt` (`TransitSizes.badgeRadius`).
- Pill / Capsule: `9999 pt` (`TransitSizes.pillRadius`).
- Bottom Sheet Handle & Radius: `24 pt` (`TransitSizes.sheetRadius`).

---

## 3. Nuovi Componenti Transit UI

1. **`TransitCard` (`transit_theme.dart`)**:
   - Card a raggio 16pt con bordo continuo, micro-ombreggiatura o contorno sottile.
   - Supporto per alert accent bar laterale da 4pt per segnalare visivamente deviazioni e ritardi.
2. **`TransitBouncingButton` (`transit_theme.dart`)**:
   - Micro-interazione fisica: compressione a scala `0.94` al tocco con rimbalzo elastico soft a `1.04` al rilascio.
   - Feedback aptico di selezione (`HapticFeedback.selectionClick`).
3. **`TransitFilterPill` (`transit_theme.dart`)**:
   - Capsula animata (`AnimatablePillStackView`) per i selettori di sezione e filtri di linea.
4. **`TransitLiveWaveIcon` (`transit_theme.dart`)**:
   - Animazione radar con anelli concentrici pulsanti per indicare chiaramente gli arrivi con segnale satellitare in tempo reale (live tracking).
5. **`TransitRouteCard` (`transit_route_card.dart`)**:
   - Ispirata alla cella `SPNearbyRouteCollectionViewCell` di Transit, con badge linea, destinazione, pill di stato e countdown orario in grande.

---

## 4. Preservazione Integrale delle Funzionalità

Tutte le funzionalità approvate e richieste finora sono presenti e perfettamente funzionanti in `test/`:
1. **Home Feed**:
   - Sezioni "Di interesse", "Linee salvate" e "Tutte le linee" con `TransitFilterPill`.
   - Card fermate e linee con badge di stato coerenti (regolare, chiusa in giornata, deviata).
2. **Widget Fermata Preferita (`FavoriteStopWidgetCard`)**:
   - Countdown in tempo reale con cifre tabulari e indicatore satellite `TransitLiveWaveIcon`.
   - Schermata di configurazione e preferenza palina.
3. **Anteprima Mappa Bus Live nelle Linee Salvate (`SavedLineMapPreview`)**:
   - Mappa integrata nella card linea con veicoli in movimento in tempo reale.
   - Pin veicolo verde Transit con freccia di direzione e contatore bus live ("n bus live").
   - Pulsante "Espandi mappa" per passare alla visuale a tutto schermo.
4. **I Miei Percorsi (`SavedJourneyScreen` & `JourneyEditorScreen`)**:
   - Supporto fino a 3 cambi (4 tratte) con indicatore a capsule del tempo a piedi.
   - Fermate preferenziali (es. percorsi protetti o stazioni principali).
   - Linee filtrate per tratta, riordino con drag-and-drop, evidenziazione delle coincidenze al tocco.
5. **Dettaglio Fermata (`StopScreen`)**:
   - Arrivi in tempo reale vs programmati con beacon live, avvisi deviazione attivi, e possibilità di fissare come preferita.
6. **Dettaglio Linea (`LineScreen`)**:
   - Mappa con percorso e veicoli live, avvisi attivi e futuri, monitoraggio live continuo.
7. **Radar Bus Live (GPS)**:
   - Sheet di monitoraggio satellitare dei bus vicini.
8. **Fermate Vicine Sheet**:
   - Elenco fermate nel raggio dell'utente con distanze e direzioni.
9. **Banner Sciopero (`_ScioperoBanner`)**:
   - Avviso prioritario con fasce di garanzia e linee coinvolte.
10. **Ricerca e Line Picker**:
    - Selezione rapida con badge e feedback di digitazione.

---

## 5. Verifica Qualità

- `flutter analyze`: **0 errori, 0 avvisi** (Clean).
- `flutter test`: **Tutti i test unitari e di widget superati con successo**.
