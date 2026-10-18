# 04 — Layout, Spaziatura e Geometria

> **File:** `Transit_Design_System/04_Layout_Spaziatura_e_Geometria.md`  
> **Oggetto:** Griglia dimensionale a 4/8pt, geometria squircle Apple, architettura a 3 snap del Bottom Sheet, livelli di elevazione e target di tocco.

---

## 📐 1. La Griglia Spaziale a 4/8pt

L'intera architettura visiva di Transit è vincolata a un sistema di griglia basato su multipli di **4pt** e **8pt**, che garantisce proporzioni armoniose su schermi di qualsiasi densità di pixel (@2x, @3x):

| Token Spaziatura | Dimensione (pt) | Utilizzo Tipico nel Layout |
| :--- | :--- | :--- |
| `spacing-xxs` | `2pt` | Spazio tra icone di stato e testi micro, spessore bordi pin |
| `spacing-xs` | `4pt` | Distanza interna tra sigla della linea e icona del mezzo |
| `spacing-sm` | `8pt` | Margine tra il countdown dei minuti e l'icona dell'onda live |
| `spacing-md` | `12pt` | Padding orizzontale all'interno delle pillole di filtro modale |
| `spacing-base` | `16pt` | Padding standard interno delle schede linea (`RouteCell`), margini laterali schermo |
| `spacing-lg` | `20pt` | Distanza tra sezioni differenti (es. tra linee preferite e linee vicine) |
| `spacing-xl` | `24pt` | Raggio angoli superiori del Bottom Sheet, padding dei modali |
| `spacing-2xl` | `32pt` | Margine inferiore sopra la Home Bar in modalità a schermo intero |
| `spacing-3xl` | `48pt` | Altezza standard minima dei bottoni di azione fluttuanti (FAB) |

---

## 🔲 2. Geometria Squircle (Curvatura Continua)

Nelle animazioni Lottie dell'app (`privacy-prompt.json`), le geometrie sono definite esplicitamente come **`SquircleB5`** (superellisse con curvatura continua $G^2$). A differenza degli angoli arrotondati standard dei rettangoli CSS che creano una brusca discontinuità visiva nel punto di tangenza, lo squircle sfuma dolcemente la curvatura:

$$\left|\frac{x}{a}\right|^n + \left|\frac{y}{b}\right|^n = 1 \quad \text{con } n \approx 4.5 \text{ (curvatura continua iOS)}$$

### Raggi di Curvatura Standard
- **Card di Linea (`SPNearbyRouteCollectionViewCell`):** `14pt - 16pt` (squircle continuo su tutti e 4 gli angoli).
- **Badge di Linea e Pillole di Stato (`AnimatablePillStackView`):** `9999pt` (forma a capsula perfetta).
- **Bottom Sheet Principale (`BottomSheetView`):** `24pt` unicamente sui due angoli superiori sinistro e destro.
- **Riquadri di Sigla Linea (Boxed Badge):** `6pt - 8pt`.

---

## 📱 3. Il Bottom Sheet a 3 Snap Points (Il Cuore di Transit)

Il componente architetturale cardine di Transit è il **Bottom Sheet tridimensionale interattivo** posizionato sopra la mappa vettoriale:

```
┌───────────────────────────────────────┐
│              LIVE MAP                 │
│         (Mappa interattiva)           │
│                                       │
│   [📍 Pin Fermata]                     │
│                                       │
│    [🧭 Bussola]        [📍 Ricentra]  │
├───────────────────────────────────────┤ ─── Snap 3: FULL (~90% H)
│                 ════                  │     Lista completa linee e filtri
│           [Tutti] [Metro] [Bus]       │
├───────────────────────────────────────┤ ─── Snap 2: HALF (~45-50% H)
│ ┌───────────────────────────────────┐ │     Linee vicine più rilevanti
│ │ 80  VERSO DUOMO           3 min 🟢│ │
│ └───────────────────────────────────┘ │
├───────────────────────────────────────┤ ─── Snap 1: PEEK (~110-120 pt)
│  (Linea primaria + countdown rapido)  │     Minimo ingombro sulla mappa
└───────────────────────────────────────┘
```

### Comportamento degli Snap:
1. **Snap 1 — Peek Mode (`~110-120 pt`):**  
   Mostra unicamente la testata della prima linea disponibile e il suo conto alla rovescia. Lascia l'85% dello schermo libero per l'esplorazione geografica della mappa.
2. **Snap 2 — Half Sheet (`~45-50% altezza display`):**  
   Lo stato predefinito all'apertura dell'app. Mostra le 3-4 linee di transito più prossime con orari di arrivo in tempo reale.
3. **Snap 3 — Full Sheet (`~88-92% altezza display`):**  
   Raggiunto tramite trascinamento verso l'alto con inerzia. Espande la visualizzazione ad elenco completo con la barra dei filtri multimodali orizzontale in testa.
4. **Maniglia di Trascinamento (Handlebar):**  
   Dimensioni: `36 x 4 pt`, centrata orizzontalmente a `8pt` dal bordo superiore del foglio.  
   Colore: `rgba(0, 0, 0, 0.20)` in tema chiaro, `rgba(255, 255, 255, 0.25)` in tema scuro.

---

## 🌫️ 4. Elevazione, Ombre e Profondità (`transitLib::vm::Shadow`)

Transit adotta una scala di profondità calibrata per far galleggiare gli elementi attivi sopra la mappa geografica:

```cpp
// Struttura C++ estratta dal ViewModel di Transit
struct Shadow {
    float x;
    float y;
    float blur;
    float spread;
    Color color;
};
```

| Livello di Elevazione | Offset (X, Y) | Sfocatura (Blur) | Opacità Colore | Componenti Assegnati |
| :--- | :--- | :--- | :--- | :--- |
| **Elevation 0 (Piano Base)** | `(0, 0)` | `0pt` | 0% | Mappa vettoriale, sfondo base |
| **Elevation 1 (Card di Linea)** | `(0, 2pt)` | `4pt - 6pt` | `rgba(0, 0, 0, 0.08)` | Schede linea all'interno dell'elenco |
| **Elevation 2 (Elementi FAB)** | `(0, 4pt)` | `8pt - 12pt`| `rgba(0, 0, 0, 0.16)` | Pulsante Bussola (`CompassButton`), pulsante "GO" |
| **Elevation 3 (Bottom Sheet)** | `(0, -6pt)`| `16pt - 24pt`| `rgba(0, 0, 0, 0.22)` | Bordo superiore del Bottom Sheet sopra la mappa |
| **Elevation 4 (Modali & Alert)**| `(0, 8pt)` | `32pt` | `rgba(0, 0, 0, 0.35)` | Dialoghi di conferma, schermate di acquisto Royale |

---

## 👆 5. Ergonomia e Zone di Tocco (Touch Targets)

- **Target di Tocco Minimo:** `44 x 44 pt` effettivi (anche quando l'icona visibile misura `24 x 24 pt`, il padding invisibile espande la sensibilità al tocco).
- **Interazione a Una Mano (One-Handed Rule):** Tutti i controlli ad alta frequenza (cambio direzione con swipe orizzontale, avvio navigazione GO, espansione scheda) sono collocati nel **terzo inferiore** dello schermo, azionabili con il solo pollice.
