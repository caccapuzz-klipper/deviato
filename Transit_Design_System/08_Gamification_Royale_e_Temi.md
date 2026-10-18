# 08 — Gamification, Transit Royale e Personalizzazione Temi

> **File:** `Transit_Design_System/08_Gamification_Royale_e_Temi.md`  
> **Oggetto:** Sistema Transit Royale, collezioni di oltre 250 temi e icone, gamification della navigazione GO, avatar e sponsorizzazioni territoriali.

---

## 👑 1. L'Ecosistema "Transit Royale"

Transit ha introdotto *Transit Royale* come modello di monetizzazione etico e trasparente, ma dal punto di vista del design lo ha trasformato in un'esperienza di personalizzazione identitaria e affettiva.

Motto ufficiale estratto dall'app:
> *"Feel at home with your choice of 250 app icons and themes."*  
> *"Custom themes are a royal perk. Love Transit? Get Royale."*

---

## 🎨 2. L'Architettura dei Temi (`ThemeManager`)

All'interno del codice di Transit, il gestore dei temi (`ThemeManagerProtocol` / `RoyaleAppTheme`) controlla l'aspetto dell'intera applicazione tramite 5 strati cromatici indipendenti:

```
┌────────────────────────────────────────────────────────┐
│  1. Icon Background    (theme_preview_5_icon_background)
│  2. Primary Accent     (royale_feature_theme_primary_background)
│  3. Content Foreground (theme_preview_4_content_color)
│  4. Surface Shadows    (theme_preview_1_shadows_color)
│  5. Glow Accent        (theme_preview_7_icon_glow_color)
└────────────────────────────────────────────────────────┘
```

### Le Categorie dei Temi:
1. **Temi Ufficiali delle Agenzie di Trasporto:**  
   Collezioni cromatiche che riproducono fedelmente le identità grafiche storiche:
   - *London Heritage:* I colori delle linee dell'Underground di Transport for London (`icon_transport_for_london_*`).
   - *Vancouver TransLink:* Le tonalità pacifiche blu e grigie della British Columbia.
   - *Chicago 'L':* La palette iconica CTA (`Chicago Pink`, `Chicago Blue`, `Chicago Brown`).
   - *New York City Subway:* Le lettere e i cerchi storici MTA.
2. **Temi Atmosferici e Pop:**  
   Neon Cyberpunk, Retro 80s Synthwave, Minimal Monochrome, Forest Trail, Pastel Morning.
3. **Temi Ironici e Segreti:**  
   Temi sbloccabili tramite *easter egg* legati ad eventi o festività locali.

---

## 🏆 3. Gamification della Navigazione "GO" e Leaderboard

Transit premia i pendolari che accendono la navigazione "GO" e trasmettono dati GPS anonimi alla comunità con una serie di elementi di gamification visuale:

### A. La Corona della Linea (`crown`, `crown-detailed`, `crown-flag`)
- Il passeggero che ha accumulato più corse GO su una specifica linea nel corso dell'ultimo mese diventa il **Re o la Regina della Linea** (*Line VIP / Royale Crown*).
- La sua foto o avatar viene impreziosita con la corona d'oro (`royale_crown_color` `#FFC107`).
- Quando gli altri utenti salgono su quella linea, vedono l'avatar coronato nella schermata di dettaglio.

### B. Sistema Avatar Circolare (`avatar-circle`, `avatar-royale-ring`)
- L'avatar dell'utente è racchiuso in un anello con spessore di `3pt`.
- Per gli utenti Royale, l'anello si arricchisce di un gradiente violaceo-dorato rotante e di un bagliore esterno soffuso (`theme_preview_7_icon_glow_color`).

---

## ☕ 4. Segnaletica Micro-Emotiva per le Destinazioni

Per i luoghi preferiti salvati dall'utente (oltre ai classici "Casa" e "Lavoro"), Transit offre una serie di micro-icone illustrative calorose:

| Asset Name | Icona Illustrata | Contesto d'Uso |
| :--- | :--- | :--- |
| `coffee.directions` | Tazzina da caffè fumante | Bar / Luogo della colazione |
| `burger.directions` | Panino hamburger stilizzato | Ristorante preferito o pausa pranzo |
| `cocktail.directions` | Bicchiere da drink con cannuccia| Bar serale / Ritrovo tra amici |
| `couch.directions` | Divano accogliente | Casa del partner o di amici |
| `ball.directions` | Palla da sport | Palestra, campo sportivo o stadio |
| `bear.directions` | Orsetto amichevole | Scuola, asilo o parco naturale |

---

## 🤝 5. Modello Royale Sponsorizzato dalle Agenzie

Quando un'autorità metropolitana di trasporto (es. MUNI a San Francisco, NORTA a New Orleans, YRT a York Region) decide di finanziare il servizio per i propri cittadini, Transit applica le regole di co-branding:
- Logo dell'agenzia incorporato nella testata (`sponsored-royale-logo-*`).
- Banner di benvenuto personalizzato con il messaggio: *"Offerto dalla tua agenzia locale per ringraziarti di viaggiare con noi"*.
- I colori del brand cittadino diventano il tema predefinito all'apertura dell'app.
