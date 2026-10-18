# 06 — Micro-interazioni, Sensori Aptici e Sound Design

> **File:** `Transit_Design_System/06_Microinterazioni_Aptiche_e_Suono.md`  
> **Oggetto:** Specifiche ingegneristiche dei file AHAP (Apple Haptic Audio Pattern), animazioni Lottie ed ecosistema sonoro.

---

## 📳 1. Il Sistema Aptico Personalizzato (CoreHaptics AHAP)

Transit non si limita alle vibrazioni di sistema generiche (`UIImpactFeedbackGenerator`), ma utilizza modelli aptici proprietari definiti in file `.ahap` per comunicare feedback fisici ricchi e distinti:

### A. Scansione QR Code Avvenuta (`qr-code-scanned.ahap`)
Utilizzato quando l'utente inquadra con la fotocamera il codice QR di una bicicletta condivisa, di un monopattino o di un biglietto contactless:
- **Architettura del Pattern:** Doppio impulso transiente rapido (*Double-Tap Confirmation*).
- **Evento 1 (Percezione / Aggancio del codice):**
  - Tempo: $t = 0.010\,\text{s}$
  - `HapticIntensity`: $0.453$ ($45.3\%$)
  - `HapticSharpness`: $0.453$ ($45.3\%$)
- **Evento 2 (Conferma e Sblocco):**
  - Tempo: $t = 0.125\,\text{s}$ ($\Delta t = 115\,\text{ms}$)
  - `HapticIntensity`: $0.988$ ($98.8\%$ — quasi massima potenza)
  - `HapticSharpness`: $0.988$ ($98.8\%$ — impatto metallico netto)

```json
/* Frammento estratto da Transit.app/qr-code-scanned.ahap */
{
  "Pattern": [
    {
      "Event": {
        "Time": 0.01005,
        "EventType": "HapticTransient",
        "EventParameters": [
          { "ParameterID": "HapticIntensity", "ParameterValue": 0.4529 },
          { "ParameterID": "HapticSharpness", "ParameterValue": 0.4529 }
        ]
      }
    },
    {
      "Event": {
        "Time": 0.125,
        "EventType": "HapticTransient",
        "EventParameters": [
          { "ParameterID": "HapticIntensity", "ParameterValue": 0.9882 },
          { "ParameterID": "HapticSharpness", "ParameterValue": 0.9882 }
        ]
      }
    }
  ]
}
```

---

### B. Generazione e Rimozione Cuori Crowdsourcing (`hearts-spawned.ahap` & `hearts-despawned.ahap`)
In modalità navigazione GO, quando l'utente condivide la propria posizione GPS in tempo reale per aiutare gli altri passeggeri ad aspettare l'autobus, riceve gratificazioni fisiche:
- **`hearts-spawned` (Comparsa cuore):**
  - `HapticIntensity`: $0.75$ ($75\%$)
  - `HapticSharpness`: $0.45$ ($45\%$ — sensazione morbida e rotonda, come una bolla che si gonfia).
- **`hearts-despawned` (Scomparsa cuore):**
  - `HapticIntensity`: $0.45$ ($45\%$)
  - `HapticSharpness`: $0.45$ ($45\%$ — tocco leggero di rilascio).

---

## 🎬 2. Micro-animazioni Vettoriali (Lottie Engine)

Transit integra animazioni Lottie vettoriali leggere e scalabili a qualsiasi risoluzione Retina:

| File Lottie | Frame Rate | Durata | Risoluzione Canvas | Scopo di Design |
| :--- | :--- | :--- | :--- | :--- |
| `sparkle.json` | $29.97\,\text{fps}$ | $3.00\,\text{s}$ (90 frames) | $117 \times 278\,\text{pt}$ | Particelle scintillanti d'oro attorno alla corona Royale e alle milestone |
| `heart-appears.json` | $29.97\,\text{fps}$ | $0.20\,\text{s}$ (6 frames) | $117 \times 278\,\text{pt}$ | Pop istantaneo del cuore quando un altro utente visualizza la tua corsa GO |
| `privacy-prompt.json` | $30.00\,\text{fps}$ | $2.50\,\text{s}$ | $944 \times 1680\,\text{pt}$ | Spiegazione animata dei permessi di localizzazione in Light Mode |
| `privacy-prompt-dark.json`| $30.00\,\text{fps}$ | $2.50\,\text{s}$ | $944 \times 1680\,\text{pt}$ | Controparte ottimizzata per Dark Mode con gradienti scuri |

---

## 🔔 3. Sound Design e Feedback Acustico

I suoni dell'applicazione (salvati in formato Apple CoreAudio CAF) sono calibrati per farsi sentire sopra il rumore di fondo del traffico urbano o dei motori di un autobus:

| File Audio | Durata / Peso | Tono / Carattere | Funzione UX nell'Applicazione |
| :--- | :--- | :--- | :--- |
| `ding.caf` | $83.5\,\text{KB}$ | Singolo rintocco squillante, frequenza medio-alta | Preavviso: *"Il tuo mezzo è a 2 minuti dalla fermata"* |
| `ding-ding-ding.caf`| $81.1\,\text{KB}$ | Triplo rintocco ritmato e ascendente | Allerta di discesa: *"Preparati a scendere alla prossima fermata!"* |
| `alarm.caf` | $24.4\,\text{KB}$ | Tono di sveglia incisivo e ripetitivo | Urgenza critica: fermata imminente o cambio linea immediato |
| `chime.caf` | $84.4\,\text{KB}$ | Accordo armonioso caldo e rassicurante | Corsa completata con successo, traguardo raggiunto |
