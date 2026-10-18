# 03 — Iconografia, Segnaletica e Pin Vettoriali

> **File:** `Transit_Design_System/03_Iconografia_e_Segnaletica.md`  
> **Oggetto:** Specifiche geometriche SVG dei pin di mappa, indicatori di quota e livello, segnaletica di ingresso/uscita, icone multimodali e indicatori di affollamento.

---

## 📍 1. I Pin di Mappa: Geometria ed Effetti Ombra

I pin di localizzazione in Transit sono il punto di contatto fondamentale tra il mondo fisico e la rappresentazione digitale. Sono progettati per non occludere la viabilità e per essere distinguibili a qualsiasi livello di zoom.

### A. Pin Principale di Fermata (`pin-default.svg`)
- **Dimensioni ViewBox:** `40 x 52 pt`
- **Corpo del Pin:** Forma a goccia affusolata verso il basso con raggio di raccordo arrotondato.
- **Campitura (Fill):** `#010101` (Nero profondo)
- **Bordo di Contrasto (Stroke):** `#FEFEFE` (Bianco), spessore `2pt`
- **Ombra a Terra (Radial Drop Shadow):**
  - Ellisse centrata a `cx="19.9"`, `cy="48"` con assi `rx="16.753"` e `ry="2.0"`.
  - Gradiente radiale a 5 stop con opacità progressiva:
    - Offset 0%: Opacità 100%
    - Offset 9.6%: Opacità 100%
    - Offset 50.2%: Opacità 28.9%
    - Offset 66.8%: Opacità 12.9%
    - Offset 100%: Opacità 0%
  - Filtro di sfocatura gaussiana (`feGaussianBlur`) con deviazione standard `stdDeviation="0.5"`.

```xml
<!-- Struttura SVG del Pin Standard Transit -->
<svg height="52" viewBox="0 0 40 52" width="40" xmlns="http://www.w3.org/2000/svg">
  <radialGradient id="shadowGrad" cx="50%" cy="51.25%" r="48.75%">
    <stop offset="0" stop-color="#000" stop-opacity="1"/>
    <stop offset=".502" stop-color="#000" stop-opacity=".289"/>
    <stop offset="1" stop-color="#000" stop-opacity="0"/>
  </radialGradient>
  <ellipse cx="19.9" cy="48" rx="16.753" ry="2" fill="url(#shadowGrad)"/>
  <!-- Percorso pin -->
  <path d="M0 20.1C0 31 13 47 18 48c1.25.25 2.75.25 4 0 5-1 18-17 18-27.9C40 9 31 0 20 0S0 9 0 20.1z" fill="#010101"/>
  <!-- Bordo bianco salva-contrasto -->
  <path d="..." stroke="#FEFEFE" stroke-width="2"/>
</svg>
```

---

### B. Pin di Livello e Quota Stazione (`pin-level.svg` & `pin-level-meter.svg`)
Per nodi complessi (stazioni sotterranee su più piani, stazioni sopraelevate, passerelle ferroviarie), Transit impiega un pin più compatto:
- **Dimensioni ViewBox:** `25 x 35 pt`
- **Ombra di Base:** Ellisse a `cy="31.97"`, `rx="11.5"`, `ry="1.373"`.
- **Rappresentazione del Piano:** Il pin include una tacca graduata laterale che indica all'utente se la banchina si trova al piano strada, a livello mezzanino (-1) o alle banchine profonde (-2 o -3).

---

### C. Pin di Ingresso e Uscita (`pin-entrance-enter.svg` & `pin-entrance-exit.svg`)
- **Dimensioni ViewBox:** `20 x 26 pt`
- **Caratteristiche Uniche:**
  - Nella testa del pin è incisa una **micro-freccia direzionale** (spessore `1.5pt`, colore `#FFFFFF`).
  - L'ingresso mostra la freccia puntata verso l'interno della stazione (`pin-entrance-enter`).
  - L'uscita mostra la freccia orientata verso l'esterno verso la strada (`pin-entrance-exit`).
  - Questo elimina l'ansia tipica dell'uscita dalle stazioni complesse (es. metropolitana di Tokyo, Londra o Parigi).

---

## 🚍 2. Il Set Iconografico Modale (Transit Modes)

Le icone dei mezzi di trasporto sono disegnate con uno spessore di tratto uniforme di **2pt**, angoli smussati e proporzioni racchiuse in una griglia quadrata di **24 x 24 pt** (o **16 x 16 pt** nelle versioni badge compatte):

| Categoria | Asset Nome Estratto | Significato Visivo |
| :--- | :--- | :--- |
| **Bus** | `bus` | Sagoma frontale con parabrezza orizzontale e fari distinti |
| **Treno Suburbano** | `train` | Profilo frontale aerodinamico con pantografo superiore |
| **Tram / Streetcar** | `tram` / `tranwa` | Sagoma con fari ravvicinati e palo trolley |
| **Bicicletta Personale** | `bike` | Telaio geometrico a diamante, ruote circolari senza raggi |
| **Bikeshare (Stazione)** | `bikeshare` / `bikeshare_station`| Bicicletta affiancata dal modulo rastrelliera a colonnina |
| **Monopattino Elettrico** | `scooterIcon.svg` | Pedana bassa con manubrio verticale a T |
| **Carpooling / Taxi** | `carpool` / `car_berline` | Sagoma vettura con icona passeggero o scacchiera |
| **Pedonale / Walk** | `bike-walk` / `arrow_destination` | Omino stilizzato in cammino con passo dinamico |

---

## 🧭 3. Segnaletica di Manovra per la Navigazione "GO"

Durante la modalità di navigazione passo-passo assistita, Transit utilizza un sistema rigoroso di frecce vettoriali per guidare l'utente:

| Asset Name | Angolo di Svolta | Azione Richiesta |
| :--- | :--- | :--- |
| `arrow_up` | $0^\circ$ | Procedi dritto |
| `arrow_turn_slight_left` | $-45^\circ$ | Mantieni la sinistra |
| `arrow_turn_left` | $-90^\circ$ | Svolta a sinistra |
| `arrow_turn_sharp_left` | $-135^\circ$ | Svolta decisa a sinistra |
| `arrow_turn_u_turn_left` | $-180^\circ$ | Inversione a U a sinistra |
| `arrow_turn_slight_right` | $+45^\circ$ | Mantieni la destra |
| `arrow_turn_right` | $+90^\circ$ | Svolta a destra |
| `arrow_turn_sharp_right` | $+135^\circ$ | Svolta decisa a destra |
| `arrow_incline` / `arrow_decline` | Pendenza $\pm 30^\circ$ | Scale mobili, rampe o sottopassaggi inclinati |

---

## 👥 4. Indicatori di Affollamento (Crowding Dudes)

L'indicatore di affollamento sintetizza in pochissimi pixel una complessa stima statistica/crowdsourced:
- `crowding_0_dudes`: **1 silhouette umana** verde `#34C759` $\rightarrow$ Molti posti a sedere.
- `crowding_1_dudes`: **2 silhouette umane** ambra `#FF9500` $\rightarrow$ Pochi posti o solo posti in piedi.
- `crowding_2_dudes`: **3 silhouette umane** rosse `#FF3B30` $\rightarrow$ Vagone o autobus strapieno.
- `crowding_unknown_dudes`: Silhouette grigia con contorno tratteggiato $\rightarrow$ Dato non disponibile.
