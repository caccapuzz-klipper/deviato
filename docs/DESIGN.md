# Design System DeviaTO: Apple Human Interface Guidelines (HIG)

Questo documento definisce l'architettura grafica, le decisioni di design, i componenti e la guida di stile per il restyling completo di DeviaTO secondo le Human Interface Guidelines (HIG) di Apple.

---

## 1. Audit dell'Interfaccia Attuale: Perché risulta "pesante"

L'audit analizza le schermate e i componenti originali dell'applicazione, identificando i pattern visivi Material 3 che appesantiscono l'esperienza d'uso su iOS:

| Schermata / Componente | Elementi che appesantiscono | Problema visivo | Soluzione Apple HIG |
| :--- | :--- | :--- | :--- |
| **Home (Linee e Fermate)** | Card con bordi spessi (`BorderSide(width: 1.5)`), colori di fondo ad alto contrasto (rosso/giallo saturi), pulsanti riempiti multipli dentro ogni card, `SegmentedButton` Material squadrato. | L'occhio viene sovraccaricato da cornici, ombre e colori d'allerta simultanei. Sembra un cruscotto industriale piuttosto che un'app nativa iOS. | `CupertinoListSection.insetGrouped` con angoli continui R=10, `CupertinoSlidingSegmentedControl`, separatori hairline sottili, testo in gerarchia SF Pro, badge discreti. |
| **Navigazione Home (Drawer)** | Drawer laterale hamburger con banner scuro e lista opzioni a tutta larghezza. | Pattern tipicamente Android; su iOS il drawer interrompe il flusso spaziale e nasconde le sezioni chiave. | Tab bar nativa o Segmented Control con Large Title e navigation bar translucida. |
| **Scheda Linea (`LineScreen`)** | Box di riassunto con cornici multiple, pulsanti d'azione grandi e squadrati, mappa "inscatolata" a mezza pagina con bordi. | Frammentazione visiva, poco respiro, mappa sacrificata. | Header compatto con Large Title (es. "Linea 65"), layout continuo con sezioni raggruppate, mappa ad alta leggibilità, bottom sheet trascinabile per i dettagli. |
| **Mappa del Percorso (`LineMap`)** | Marker fermate enormi (icone cerchiate con testo palina sempre visibile), linee percorso spesse con contorni neri marcati, pulsanti fluttuanti grandi con ombra marcata. | Quando si rimpicciolisce la mappa, le fermate si sovrappongono creando macchie visive illeggibili. | Marker stop minimali: piccoli cerchi con anello sottile (5-6 pt) senza etichette a zoom basso; polyline elegante da 4-5 pt; pulsanti di controllo circolari con blur translucido (sfocatura frosted glass). |
| **Scheda Fermata (`StopScreen`)** | Intestazione standard Material, ListTiles con badge spessi, avvisi urlati in banner rossi. | Mancanza di coerenza con la grafica di iOS Transit/Maps. | `CupertinoSliverNavigationBar` con codice palina discreto, lista transiti in `CupertinoListSection.insetGrouped`, orari a destra in grigio/blu tenue. |
| **Ricerca (`LinePicker`)** | `TextField` con bordo Material, pulsanti di chiusura standard. | Ingombrante e disallineato rispetto alla ricerca nativa iOS. | `CupertinoSearchTextField` con sfondo semi-trasparente, angoli arrotondati e icona lente sottile. |
| **Percorsi con Cambi (`SavedJourneyScreen`)** | Card annidate con frecce spesse, pulsanti di highlight con bordi e sfondi colorati. | Troppi livelli visivi (card dentro card dentro container). | Timeline snella con indicatori circolari e linea continua di connessione, step raggruppati in una sola card pulita. |
| **Informazioni & Impostazioni (`InfoScreen`)** | Elenco schede con bordi e icone colorate disomogenee. | Aspetto frammentato. | `CupertinoListSection.insetGrouped` in perfetto stile app *Impostazioni* di iOS. |

---

## 2. Decisioni di Stile e Linguaggio Visivo (HIG)

### 2.1 Tipografia (San Francisco / Dynamic Type)
Seguiamo la scala tipografica standard iOS, garantendo pieno supporto a Dynamic Type:
* **Large Title**: 34 pt, Bold. Diventa inline (17 pt Semibold) durante lo scorrimento verso l'alto (`CupertinoSliverNavigationBar`).
* **Section Header**: 13 pt, Regular / Semibold, con testo secondario (grigio), non invadente.
* **Body / Title**: 17 pt, Regular. È la dimensione di riferimento per la lettura naturale.
* **Subtitle / Secondary**: 15 pt, Regular, colore secondario (`CupertinoColors.secondaryLabel`).
* **Caption / Footnote**: 12-13 pt, Regular, per orari, paline o dettagli minori.
* **Tono del testo**: Calmo, sobrio, informativo. Mai punti esclamativi o "ATTENZIONE!" urlati in maiuscolo; usiamo diciture chiare come *"Non servita fino al 12 novembre"* o *"Linea deviata per lavori"*.

### 2.2 Tavolozza dei Colori

#### Modalità Chiara (Light Mode)
* **Sfondo di sistema**: `CupertinoColors.systemGroupedBackground` (`#F2F2F7` - grigio chiarissimo rilassante).
* **Superfici Card / Raggruppamenti**: `CupertinoColors.secondarySystemGroupedBackground` (`#FFFFFF` - bianco puro).
* **Testo primario**: `CupertinoColors.label` (`#000000`).
* **Testo secondario**: `CupertinoColors.secondaryLabel` (`#8E8E93` - grigio neutro).
* **Separatori di linea**: Hairline (`#3C3C43` al 20% di opacità).

#### Modalità Scura (Dark Mode)
* **Sfondo di sistema**: `CupertinoColors.systemGroupedBackground` (`#000000` - nero OLED profondo).
* **Superfici Card / Raggruppamenti**: `CupertinoColors.secondarySystemGroupedBackground` (`#1C1C1E` - grigio scuro neutro).
* **Testo primario**: `CupertinoColors.label` (`#FFFFFF`).
* **Testo secondario**: `CupertinoColors.secondaryLabel` (`#8E8E93`).
* **Separatori di linea**: Hairline (`#545458` al 40% di opacità).

#### Colori Semantici (Stato delle Linee e Fermate)
* **Accento Principale (Azioni, Selezione)**: Blu iOS (`#007AFF`).
* **Regolare / In orario**: Verde iOS (`#34C759`).
* **Avviso programmato / Sciopero futuro**: Arancione iOS (`#FF9500`).
* **Non servita / Tratta deviata / Errore**: Rosso iOS (`#FF3B30`).
* **Live Radar / Mezzi in movimento**: Viola / Indaco iOS (`#AF52DE` / `#5856D6`).

---

### 2.3 Forme, Raggi e Spaziature
* **Bordi e Separatori**: Nessun bordo pesante o spesso. Usiamo separatori sottili (hairline `0.5 pt`) tipici delle liste raggruppate di iOS.
* **Angoli Arrotondati**: Raggio continuo di `10-12 pt` per tutte le card e sezioni raggruppate; `8 pt` per i badge e i pulsanti compatti.
* **Ombre**: Quasi del tutto assenti (`BoxShadow` con blur leggerissimo o nulle). La distinzione delle superfici è affidata al contrasto tra lo sfondo grouped e la superficie della card.
* **Spaziature (Padding & Margini)**:
  * Margine laterale standard: `16 pt`.
  * Padding interno raggruppamenti: `12-16 pt`.
  * Altezza minima elementi interattivi / bottoni: `44x44 pt` (conformità alle linee guida di accessibilità Apple).

---

### 2.4 Componenti Chiave Riutilizzabili (`app_theme.dart` & Componenti)
Per mantenere il codice manutenibile e centralizzato, creiamo:
1. **`AppTheme` / `AppleTheme`**: palette colori, stili di testo iOS, costanti di raggio e spaziature.
2. **`AppGroupedSection`**: Wrapper stile `CupertinoListSection.insetGrouped` per raggruppare informazioni correlate.
3. **`AppListTile`**: Riga interattiva con titolo, sottotitolo, eventuale trailing e `CupertinoListTileChevron`.
4. **`StatusPill`**: Badge discreto ed elegante (sfondo con 12-15% di opacità, testo colorato) per indicare deviazioni, regolarità o transiti live.
5. **`TranslucentBar`**: Barra superiore e inferiore con `BackdropFilter` (frosted glass) che sfoca elegantemente i contenuti sottostanti nel rispetto delle preferenze di accessibilità del sistema.

---

### 2.5 Linee Guida per la Mappa (Stile Apple Maps)
* **Cartografia**: Tile OpenStreetMap desaturati e puliti, privi di rumore visivo.
* **Percorso**: Spessore sottile (`4 pt`) con leggera traccia di contorno (`1 pt`), differenziando visivamente la tratta regolare (blu) da quella deviata (rosso).
* **Fermate**: Punti circolari minimali (diametro `6 pt`) con anellino sottile. La fermata selezionata mostra un alone delicato (`12 pt`).
* **Pulsanti di controllo**: Piccoli pulsanti circolari bianchi/traslucidi (stile Apple Maps) posizionati in alto a destra.
