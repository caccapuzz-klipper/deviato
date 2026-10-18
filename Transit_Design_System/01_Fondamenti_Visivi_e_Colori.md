# 01 — Fondamenti Visivi e Sistema Colore

> **File:** `Transit_Design_System/01_Fondamenti_Visivi_e_Colori.md`  
> **Oggetto:** Principi cromatici, palette semantica, motore colore GTFS adattivo, modalità Dark/Light.

---

## 🎨 1. La Filosofia Cromatica di Transit

A differenza delle tradizionali applicazioni che impongono un'identità cromatica fissa, il sistema colore di Transit opera su due livelli paralleli:
1. **L'Identità di Sistema (Transit Core):** Verde vibrante per la navigazione attiva, neri puri OLED per ridurre il consumo di batteria, e bianco pulito ad altissima riflettenza per il massimo contrasto in esterni.
2. **L'Identità Adattiva (Agency & Route Colors):** L'interfaccia cede il protagonismo ai colori ufficiali delle linee di trasporto pubblico fornite dai feed **GTFS** (General Transit Feed Specification). L'app applica in tempo reale una formula di calcolo del contrasto per garantire la leggibilità.

---

## 🟢 2. Palette Primaria e di Sistema

| Token | Valore Hex | Valore RGB | Utilizzo Principale |
| :--- | :--- | :--- | :--- |
| `color-brand-green` | `#02B875` | `rgb(2, 184, 117)` | Colore primario del brand Transit, pulsanti di avvio "GO", tracciamento GPS attivo |
| `color-brand-green-vibrant` | `#00C853` | `rgb(0, 200, 83)` | Accento live, indicatore di orario in tempo reale (onde GPS) |
| `color-brand-dark-base` | `#010101` | `rgb(1, 1, 1)` | Nero profondo OLED. Usato per la Dark Mode nativa, pin vettoriali, testo su sfondi chiari |
| `color-brand-white` | `#FEFEFE` | `rgb(254, 254, 254)` | Bianco ultra-puro. Usato per bordature di pin, icone su sfondi di linea scuri, testo ad alto contrasto |
| `color-surface-dark-1` | `#1C1C1E` | `rgb(28, 28, 30)` | Sfondo principale delle schede in Dark Mode |
| `color-surface-dark-2` | `#2C2C2E` | `rgb(44, 44, 46)` | Sfondo secondario, elementi selezionati, bordi sottili in Dark Mode |
| `color-surface-light-1` | `#FFFFFF` | `rgb(255, 255, 255)` | Sfondo schede in Light Mode |
| `color-surface-light-2` | `#F2F2F7` | `rgb(242, 242, 247)` | Sfondo di pagina e raggruppamento sezioni in Light Mode |

---

## 🔄 3. Il Motore di Colore Dinamico GTFS (`TransitUtils::Color`)

Nel codice compilato (`transitLib::vm` e `TransitUtils::Color`), Transit implementa un modello a doppio stato cromatico:
```cpp
Color = {
    "light": { RawColor: "red"f, "blue"f, "green"f, "alpha"f },
    "dark":  optional<TransitUtils::RawColor>
}
```

### Regole di Calcolo del Contrasto per le Linee
Quando Transit riceve il parametro `route_color` da un'agenzia:
1. **Calcolo della Luminanza Relativa ($L$):**
   $$L = 0.2126 \cdot R_{lin} + 0.7152 \cdot G_{lin} + 0.0722 \cdot B_{lin}$$
2. **Determinazione del Testo Sovrapposto (`textColor` / `boxedTextColor`):**
   - Se il contrasto con `#FFFFFF` è $\ge 4.5:1$, il testo e l'icona della linea vengono renderizzati in **Bianco (`#FEFEFE`)**.
   - Se il contrasto è insufficiente (linee gialle, azzurre chiare, bianche, come la linea gialla di Madrid o la linea argento di Boston), il testo viene renderizzato in **Nero (`#010101`)**.
3. **Pillole Inscatolate (`boxedTextColor`):**
   Per le linee con colori pastello o a contrasto marginale, la sigla della linea viene incapsulata in un badge rettangolare smussato con bordo ad alto contrasto di `1.5pt` (`stroke="#fefefe"`).

---

## 🚦 4. Palette Semantica e di Stato

### Stato del Servizio (Service Health)
| Stato | Token | Hex | Descrizione / Componente |
| :--- | :--- | :--- | :--- |
| **Servizio Regolare** | `color-status-good` | `#34C759` | `GoodServiceCell`, badge "In orario" |
| **Rallentamento / Ritardo** | `color-status-delay` | `#FF9500` | Ritardi superiori a 3 minuti, countdown evidenziato |
| **Avviso / Allerta** | `color-status-warning` | `#FFA000` | `alert_warning_no_padding_color`, `suv_warning_color` |
| **Interruzione / Chiuso** | `color-status-danger` | `#FF3B30` | `entrance_pin_big_closed_color`, fermata soppressa, deviazione |

### Livelli di Affollamento (Crowding Levels)
Transit visualizza il livello di affollamento a bordo con 3 livelli discreti e icone sagomate (`crowding_dudes`):
- **Livello 0 (Posti a sedere disponibili):** `#34C759` (Verde chiaro)
- **Livello 1 (Solo posti in piedi):** `#FF9500` (Ambra)
- **Livello 2 (Completamente pieno / Non sale nessuno):** `#FF3B30` (Rosso vivo)
- **Sconosciuto:** `#8E8E93` (Grigio neutro medio)

---

## 👑 5. Palette "Transit Royale" e Temi Speciali

Per gli abbonati a Transit Royale e le agenzie partner, l'applicazione offre un'esperienza visiva premium:

| Token | Valore Hex | Descrizione |
| :--- | :--- | :--- |
| `color-royale-purple` | `#6C3CE9` | Viola regale primario, icona corona Royale (`royale_logo_color`) |
| `color-royale-purple-dark`| `#4D23B8` | Gradiente di sfondo per i modali Royale e le card upsell |
| `color-royale-gold` | `#FFC107` | Oro lucido per la corona utente (`royale_crown_color`), stelle e leaderboard |
| `color-royale-pink` | `#E040FB` | Accento per eventi speciali e percorsi ciclabili preferiti |
| `color-royale-glow` | `rgba(108, 60, 233, 0.35)` | `theme_preview_7_icon_glow_color`, bagliore attorno agli avatar |

---

## 🌗 6. Linee Guida per Light & Dark Mode

Transit segue fedelmente il tema di sistema iOS (`UIAppearanceAny`, `UIAppearanceDark`, `UIAppearanceLight`), ma adotta accorgimenti specifici:
1. **La Mappa:**
   - In Light Mode, la mappa utilizza toni desaturati (grigio chiaro per gli isolati, azzurro tenue per i fiumi, verde salvia per i parchi), in modo che **le linee di transito colorate risaltino istantaneamente**.
   - In Dark Mode, la mappa diventa grigio antracite `#121212`, eliminando l'abbagliamento notturno.
2. **I Pin e i Marker:**
   - I pin vettoriali (`pin-default.svg`) mantengono la sagoma nera profonda `#010101` contornata da una linea di separazione bianca `#FEFEFE` di `2pt`, garantendo visibilità assoluta sia su mappe scure che su mappe chiare.
3. **Le Card delle Linee:**
   - In Dark Mode, le card delle linee non subiscono una semplice inversione, ma mantengono il colore pieno della linea con un leggero abbassamento della saturazione (8-10%) per evitare affaticamento visivo.
