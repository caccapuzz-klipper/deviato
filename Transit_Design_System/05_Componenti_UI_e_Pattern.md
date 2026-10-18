# 05 — Componenti UI e Pattern di Interazione

> **File:** `Transit_Design_System/05_Componenti_UI_e_Pattern.md`  
> **Oggetto:** Specifiche costruttive dei componenti chiave: LineCard (`RouteCell`), DepartureBadge, AnimatablePill, BouncingButton, Banner di disservizio e HUD navigazione GO.

---

## 🚏 1. La Scheda di Linea (`SPNearbyRouteCollectionViewCell` / `RouteCard`)

La `RouteCard` è l'atomo fondamentale dell'interfaccia di Transit. Ogni scheda rappresenta una linea di trasporto e sintetizza identità, direzione e tempo di attesa:

```
┌─────────────────────────────────────────────────────────────┐
│  ┌─────┐                                                    │
│  │ 80  │  VERSO DUOMO                            4 min 🟢   │
│  │ 🚌  │  Fermata: Via Dante                      12 • 25   │
│  └─────┘  Ogni 8 min • Climatizzato                         │
└─────────────────────────────────────────────────────────────┘
```

### Anatomia e Specifiche Tecniche:
- **Altezza:** `72pt` (standard) / `88pt` (con avvisi di ritardo o dettagli aggiuntivi).
- **Sfondo:** Colore ufficiale della linea (`route_color` GTFS) oppure superficie neutra (`#1C1C1E` scuro / `#FFFFFF` chiaro) con barra laterale colorata di `6pt`.
- **Blocco Sinistro (Identificatore di Linea):**
  - Riquadro compatto con raggio squircle `8pt`.
  - Sigla linea in font `PuffinTransit-Bold` (`20pt`).
  - Micro-icona del veicolo (`14 x 14 pt`) posizionata sotto o a fianco della sigla.
- **Blocco Centrale (Destinazione & Contesto):**
  - Titolo direzione in font `PuffinTransit-SemiBold` (`17pt`), allineato a sinistra con troncamento intelligente (*middle-truncation* se necessario per preservare la parola finale).
  - Sottotitolo con il nome della banchina o della fermata (`13pt Regular`).
- **Blocco Destro (Countdown & Stato Live):**
  - Orario principale in `PuffinTransit-ExtraBold` (`32pt - 36pt`).
  - Indicatore di onde radio pulsanti (indica che l'orario è calcolato su tracciamento GPS in tempo reale del veicolo, non su tabelle orarie statiche).
  - Orari successivi secondari in `13pt SemiBold` (`12 • 25 min`).
- **Gesto di Swipe Orizzontale (Direction Flip):**
  - Uno swipe orizzontale verso sinistra o verso destra sulla scheda **inverte istantaneamente la direzione di marcia della linea** con un feedback aptico transiente e una transizione 3D card-flip fluida.

---

## 💊 2. Pillole di Filtro Modale (`AnimatablePillStackView`)

Barra di scorrimento orizzontale posizionata in testa al Bottom Sheet per consentire il filtraggio istantaneo delle modalità di trasporto:

- **Altezza Pillola:** `34pt`.
- **Raggio di Curvatura:** `9999pt` (Capsule).
- **Padding Orizzontale:** `14pt` (sinistra/destra), `8pt` tra icona e testo.
- **Stato Inattivo:**
  - Sfondo: `rgba(0, 0, 0, 0.06)` (chiaro) / `rgba(255, 255, 255, 0.12)` (scuro).
  - Testo e icona: Colore neutro secondario.
- **Stato Attivo:**
  - Sfondo: Verde Transit `#02B875` o Nero pieno `#010101` in base al contesto.
  - Testo e icona: Bianco `#FEFEFE` in font `PuffinTransit-Bold` (`14pt`).
  - Micro-animazione: Espansione a molla (*spring bounce*) di `+4pt` in larghezza quando selezionata.

---

## 🔘 3. Pulsanti con Effetto Rimbalzo (`BounceButtonStyle` / `BouncingCloseButton`)

Tutti i bottoni primari di Transit (il tasto "GO", il pulsante di chiusura `BouncingCloseButton`, i tasti di conferma) implementano una fisica a molla proprietaria:

### Curve di Animazione e Scala:
- **Pressione (Touch Down):**
  - Scala dell'elemento ridotta a `0.94` ($94\%$).
  - Durata transizione: `0.15s` (curva `ease-out`).
  - Generazione immediata di un feedback aptico transiente leggero.
- **Rilascio (Touch Up):**
  - Scala che rimbalza a `1.04` per poi assestarsi a `1.00`.
  - Durata: `0.35s` con smorzamento a molla (*damping ratio* `0.65`).

---

## ⚠️ 4. Banner di Allerta e Disruzioni (`AlertCell` / `GoodServiceCell`)

- **`GoodServiceCell` (Servizio Regolare):**
  - Sottile riga orizzontale con spunta circolare verde `circle_checkmark_with_padding` e testo "Servizio regolare su tutta la linea".
- **`AlertCell` (Disservizi o Lavori in Corso):**
  - Bordo sinistro ambra `#FF9500` o rosso `#FF3B30` di spessore `4pt`.
  - Icona triangolare di pericolo `alert_warning_no_padding_color`.
  - Testo riassuntivo in `14pt SemiBold` espandibile con tap per rivelare i dettagli del cantiere, la data di ripristino e le fermate soppresse.

---

## 🧭 5. L'HUD di Navigazione Passo-Passo "GO" (`GOBottomSheetView`)

Quando l'utente attiva la modalità navigazione "GO":
1. **Colorazione a Schermo Intero:** L'interfaccia adotta lo schema cromatico della linea in corso.
2. **Istruzione Gigante a Basso Carico Cognitivo:**
   - La prossima azione ("Scendi tra 2 fermate", "Svolta a destra su Via Roma") viene renderizzata in `PuffinTransit-ExtraBold` a `28pt`.
3. **Barra di Avanzamento Dinamica:**
   - Una barra orizzontale di `6pt` sul bordo superiore del foglio indica la percentuale di percorso completata.
4. **Schermata di Fine Corsa (`EndOfRideCardView`):**
   - Schermata di ringraziamento crowdsourcing con cuori animati (`playAnimationWithHaptics:heartsCount:`), conteggio degli utenti aiutati e punti esperienza Royale accumulati.
