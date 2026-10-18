# Transit App — Design System & Linee Guida di Progettazione

> **Analisi e Documentazione Ufficiale Reverse-Engineered**  
> **Applicazione:** *Transit: Subway & Bus Times* (`com.samvermette.Transit`)  
> **Versione:** 6.1.7 (Build 54437) — iOS / iPadOS / watchOS  
> **Sviluppatore:** Transit App, Inc. (Montreal, QC, Canada)  
> **Riconoscimenti:** Vincitore Apple Design Award, standard di riferimento globale per l'Information Design e la mobilità urbana.

---

## 🧭 Introduzione al Design System di Transit

L'applicazione **Transit** è universalmente riconosciuta come uno dei vertici del design di interazione su dispositivi mobili. Il suo design system unisce rigore svizzero dell'informazione, principi di accessibilità visiva estrema (leggibilità in movimento, sotto la luce diretta del sole o con una mano sola in metropolitana) e un tocco di empatia e micro-interazione giocosa (Transit Royale, haptic custom, illustrazioni Lottie).

Questa raccolta di documenti formalizza e struttura tutte le regole di design, i componenti visivi, le metriche spaziali, i token tipografici, i parametri aptici e i pattern di interazione estratti direttamente dall'applicazione.

---

## 📁 Struttura della Cartella delle Regole di Design

```
Transit_Design_System/
│
├── README.md                                  # Questo documento introduttivo e panoramica architetturale
├── 01_Fondamenti_Visivi_e_Colori.md           # Sistema colore dinamico GTFS, palette semantica, dark/light mode
├── 02_Tipografia_PuffinTransit.md             # Specifiche del font esclusivo Puffin Transit Mobile & OpenType
├── 03_Iconografia_e_Segnaletica.md            # Segnaletica vettoriale SVG, pin mappa, drop shadow, marker multilivello
├── 04_Layout_Spaziatura_e_Geometria.md        # Griglia 4/8pt, squircles continui, bottom sheet a 3 snap, elevation
├── 05_Componenti_UI_e_Pattern.md              # LineCard, DepartureBadge, ModePill, BouncingButton, Crowding Indicator
├── 06_Microinterazioni_Aptiche_e_Suono.md     # Specifiche Apple Haptic Pattern (AHAP), animazioni Lottie, sound cues
├── 07_Accessibilita_e_Design_Inclusivo.md     # WCAG contrast ratio automatico, Dynamic Type, VoiceOver, mobilità ridotta
├── 08_Gamification_Royale_e_Branding.md       # Transit Royale, leaderboard, personalizzazione temi (250+ icone), avatar
│
└── tokens/
    ├── design_tokens.json                     # Token di design pronti all'uso (colori, raggi, spaziatura, durate)
    └── transit_color_palette.json             # Palette completa (brand, semantica, crowding, status, agenzie)
```

---

## 🎯 I 5 Principi Cardine del Design di Transit

### 1. **Glanceability (Leggibilità a Colpo d'Occhio)**
L'utente che usa Transit si trova spesso in condizioni estreme: corre verso una banchina, ha le mani occupate, cammina sotto la pioggia o è in un vagone affollato. L'informazione chiave (**tra quanti minuti parte il prossimo mezzo** e **in quale direzione**) deve essere decodificabile in meno di **200 millisecondi**, senza bisogno di toccare lo schermo.

### 2. **Dynamic Agency Branding (Identità Adattiva GTFS)**
Invece di imporre un colore statico dell'app, Transit cede la superficie visiva ai colori ufficiali della linea di trasporto (rosso Metro di Madrid, blu BART di San Francisco, verde MBTA di Boston). Il design system calcola algoritmicamente il contrasto per garantire che testi e badge siano sempre perfettamente leggibili sullo sfondo dinamico.

### 3. **Spatial Hierarchy: The Map-Centric Bottom Sheet**
La mappa è il contesto territoriale vivo e permanente; il foglio inferiore (Bottom Sheet) è il pannello di controllo temporale e operativo. L'utente naviga tra vista panoramica (Mappa), elenco linee vicine (Peek/Half sheet), e navigazione immersiva assistita (GO Mode a schermo intero) con transizioni fluide con accelerazione fisica.

### 4. **Micro-interazioni Multimodali (Tatto, Vista, Suono)**
Transit impiega il motore aptico Apple CoreHaptics attraverso pattern `AHAP` personalizzati con intensità e nitidezza regolate al millisecondo, abbinati a suoni di notifica distintivi (`ding.caf`, `ding-ding-ding.caf`) per avvisare di scendere dalla fermata senza guardare lo schermo.

### 5. **Bespoke Character & Playful Gamification**
L'eccellenza funzionale è arricchita dalla personalità visiva: il font proprietario *Puffin Transit*, micro-illustrazioni amichevoli (animali, oggetti quotidiani per le destinazioni), animazioni Lottie e il programma *Transit Royale* con oltre 250 temi cromatici e avatar personalizzabili.

---

## 🚀 Guida Rapida alla Consultazione

- **Per progettare l'interfaccia o un nuovo componente:** consultare [04_Layout_Spaziatura_e_Geometria.md](file:///c:/Users/marco/Desktop/New%20folder/Transit_Design_System/04_Layout_Spaziatura_e_Geometria.md) e [05_Componenti_UI_e_Pattern.md](file:///c:/Users/marco/Desktop/New%20folder/Transit_Design_System/05_Componenti_UI_e_Pattern.md).
- **Per implementare colori e contrasto:** consultare [01_Fondamenti_Visivi_e_Colori.md](file:///c:/Users/marco/Desktop/New%20folder/Transit_Design_System/01_Fondamenti_Visivi_e_Colori.md) e il file token [tokens/transit_color_palette.json](file:///c:/Users/marco/Desktop/New%20folder/Transit_Design_System/tokens/transit_color_palette.json).
- **Per implementare la tipografia:** consultare [02_Tipografia_PuffinTransit.md](file:///c:/Users/marco/Desktop/New%20folder/Transit_Design_System/02_Tipografia_PuffinTransit.md).
- **Per feedback aptici, suoni e animazioni:** consultare [06_Microinterazioni_Aptiche_e_Suono.md](file:///c:/Users/marco/Desktop/New%20folder/Transit_Design_System/06_Microinterazioni_Aptiche_e_Suono.md).
- **Per esportare i token in Figma, iOS (SwiftUI) o Web (CSS/Tailwind):** consultare la cartella [tokens/](file:///c:/Users/marco/Desktop/New%20folder/Transit_Design_System/tokens/).
