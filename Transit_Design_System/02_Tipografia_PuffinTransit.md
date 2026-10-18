# 02 — Tipografia Esclusiva: Puffin Transit Mobile

> **File:** `Transit_Design_System/02_Tipografia_PuffinTransit.md`  
> **Oggetto:** Specifiche del carattere proprietario Puffin Transit Mobile, pesi, glifi OpenType, gerarchia e scale Dynamic Type.

---

## 🔤 1. Il Carattere Tipografico Ufficiale

Transit non impiega il font di sistema generico di Apple (SF Pro), bensì una font family disegnata su misura da una delle più prestigiose fonderie tipografiche europee:

- **Nome Famiglia:** `Puffin Transit Mobile` (postscript name `PuffinTransitMobile-Regular`, `PuffinTransitMobile-Bold`, ecc.)
- **Fonderia:** [Bold Monday](https://www.boldmonday.com) (Paesi Bassi)
- **Type Designer:** Pieter van Rosmalen
- **Licenza ed Esclusività:** *"This customized version of Puffin Display Soft is for exclusive use by Transit only."*
- **Obiettivo Progettuale:** Massima leggibilità a colpo d'occhio da distanze critiche e su display in movimento. Il carattere fonde la severità geometrica dei cartelli della metropolitana classica (stile Edward Johnston a Londra o Vignelli a New York) con angoli leggermente arrotondati e caldi (*soft terminal curves*).

---

## ⚖️ 2. La Famiglia dei Pesi e File TTF

All'interno dell'app bundle sono integrati **8 file TrueType Font (.ttf)** registrati in `Info.plist` sotto la chiave `UIAppFonts`:

| Peso | File Font | Caratteristiche | Ruolo nell'Interfaccia |
| :--- | :--- | :--- | :--- |
| **Regular** | `PuffinTransit-Regular.ttf` | Leggero, proporzionato, ampio respiro interno | Testi descrittivi, spiegazioni, note di servizio |
| **Italic** | `PuffinTransit-Italic.ttf` | Inclinazione corsiva fluida | Orari stimati non confermati da GPS, note legali |
| **SemiBold** | `PuffinTransit-SemiBold.ttf` | Peso medio-forte, contrasto netto | Nomi delle stazioni, direzioni di marcia, sottotitoli |
| **SemiBold Italic** | `PuffinTransit-SemiBoldItalic.ttf` | Corsivo semi-forte | Indicazioni di direzione alternative |
| **Bold** | `PuffinTransit-Bold.ttf` | Pieno, solido, grande impatto visivo | Sigle delle linee (es. `M1`, `74`, `Red Line`), pulsanti primari |
| **Bold Italic** | `PuffinTransit-BoldItalic.ttf` | Dinamismo corsivo marcato | Badge promozionali e accenti |
| **ExtraBold** | `PuffinTransit-ExtraBold.ttf` | Massima densità visiva, apertura interna generosa | Numeri del countdown dei minuti (`3 min`, `18 min`) |
| **ExtraBold Italic** | `PuffinTransit-ExtraBoldItalic.ttf` | Pressione corsiva massima | Avvisi critici istantanei in modalità "GO" |

---

## 🛠️ 3. Funzionalità OpenType Speciali (Stylistic Sets)

Nelle tabelle interne del font (`PuffinTransitMobile`), Bold Monday ha ingegnerizzato feature OpenType proprietarie specificamente per risolvere i problemi di visualizzazione dei dati di transito:

### A. I Due Punti Sollevati (Feature 263: *Shifted colon between numbers*)
Nei font standard, i due punti `:` sono allineati sul limite inferiore (baseline), lasciando troppo spazio vuoto sopra quando usati tra cifre numeriche.
- In Puffin Transit, i due punti tra due numeri (`12:45`) vengono **automaticamente centrati sull'asse verticale delle cifre tabulari**.
- Risultato: I countdown e gli orari di partenza formano un blocco monolitico compatto, senza disallineamenti visivi.

### B. Glifi Alternativi per Evitare Ambiguità Visive
Nelle reti di trasporto pubblico, la confusione tra lettere e numeri è pericolosa (ad esempio la linea `I` confusa con il numero `1`, o `O` con lo zero `0`).
- **Feature 259 (*Alternate uppercase M*):** Aste verticali dritte e vertice centrale che tocca la baseline per massima distinzione rispetto alla lettera `N`.
- **Feature 260 (*Alternate uppercase I*):** Dotata di grazie orizzontali in alto e in basso (*serifs*) per distinguerla infallibilmente dalla `l` minuscola e dalla cifra `1`.
- **Feature 256, 257, 258 (*Alternate lowercase a, g, y*):** Versioni a occhiello singolo aperto per garantire la leggibilità a grandezze microscopiche su badge di linea.
- **Feature 261 & 262 (*Bended and Curly alternates*):** Terminali curvi impiegati negli elementi grafici di Transit Royale e negli inviti dell'interfaccia.

---

## 📏 4. Scala Tipografica e Gerarchia delle Informazioni

| Livello Gerarchico | Taglia (pt) | Peso Font | Line Height | Tracking (Letter Spacing) | Esempio d'Uso |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display ETA Countdown** | `38pt - 44pt` | ExtraBold | `44pt` | Tabulare (`tnum`), `-0.5pt` | Numero minuti rimanenti (`2 min`) |
| **Header / Next Stop GO** | `26pt - 30pt` | ExtraBold | `32pt` | `-0.3pt` | Prossima svolta o fermata durante la corsa |
| **Route Code / Line Badge** | `20pt - 24pt` | Bold | `24pt` | `0pt` | Nome linea (`BART`, `43`, `Ligne 1`) |
| **Direction / Primary Title** | `17pt - 18pt` | SemiBold | `22pt` | `0pt` | Destinazione (`Verso Piazza Duomo`) |
| **Stop Name / Secondary Title**| `15pt - 16pt` | SemiBold | `20pt` | `+0.1pt` | Fermata di salita (`St-Laurent / Rachel`) |
| **Metadata / Frequency** | `13pt - 14pt` | Regular | `18pt` | `+0.2pt` | Dettaglio frequenza (`Ogni 6 min • Confermato`) |
| **Caption / Status Pill** | `11pt - 12pt` | Bold | `14pt` | `+0.5pt` (All-Caps) | Badge micro (`LIVE`, `CROWDED`, `GPS`) |

---

## ♿ 5. Regole di Supporto per Apple Dynamic Type

Il codice di Transit adotta rigidamente le proprietà UIKit e SwiftUI:
- `titleAdjustsFontForContentSizeCategory = true`
- `subtitleAdjustsFontForContentSizeCategory = true`

### Comportamento con Caratteri Grandi (Accessibility Sizes)
1. **Conservazione della Proporzione del Countdown:** Quando l'utente aumenta la dimensione dei caratteri di sistema, il blocco di arrivo (`SPNearbyRouteCollectionViewCell`) passa dinamicamente da un layout a due colonne (destra/sinistra) a un layout verticale impilato, impedendo la troncatura del numero dei minuti.
2. **Cifre Tabulari Obbligatorie (`tnum`):** Tutte le etichette con conto alla rovescia o orari utilizzano cifre a larghezza fissa per evitare che la riga salti o vibri a ogni secondo che passa.
