# 07 — Accessibilità e Design Inclusivo

> **File:** `Transit_Design_System/07_Accessibilita_e_Design_Inclusivo.md`  
> **Oggetto:** Linee guida di accessibilità (a11y), calcolo del contrasto WCAG, supporto VoiceOver, mobilità ridotta (step-free routing) e Dynamic Type.

---

## ♿ 1. Filosofia di Inclusione Universale

Per un'applicazione di trasporto pubblico utilizzata da milioni di persone ogni giorno, l'accessibilità non è un'opzione accessoria ma un requisito di sicurezza primaria. Transit è progettata per essere utilizzabile da persone ipovedenti, non vedenti, con mobilità ridotta, in sedia a rotelle o con passeggini.

---

## 👁️ 2. Calcolo Automatico del Contrasto WCAG 2.1

A causa della natura incontrollata dei colori delle agenzie di trasporto (alcune usano giallo fluo, altre azzurro slavato o grigio tenue), Transit applica un **motore algoritmico di contrasto obbligatorio**:

1. **Soglie Minime di Contrasto:**
   - **Testo Normale ($\ge 14\text{pt}$ Regular):** Rapporto di contrasto minimo $4.5:1$ (Livello AA).
   - **Testo Grande / Badge ($\ge 18\text{pt}$ Bold):** Rapporto di contrasto minimo $3.0:1$.
   - **Countdown di Partenza Critico:** Transit punta a raggiungere il livello AAA ($7.0:1$) per i numeri dei minuti.
2. **Meccanismo di Fallback Visivo:**
   - Se un colore di linea ha un contrasto insufficiente sia con il bianco che con il nero sullo sfondo della mappa:
     - La scheda di linea adotta uno **sfondo neutro scuro o chiaro**.
     - Il colore della linea viene relegato a un badge incapsulato con contorno bianco/nero di `1.5pt` (`boxedTextColor`).

---

## 🦽 3. Segnaletica per Mobilità Ridotta e Percorsi Accessibili

All'interno degli asset compilati figurano marker dedicati:

| Asset Name | Stato di Accessibilità | Significato per il Viaggiatore |
| :--- | :--- | :--- |
| `entrance_pin_big_accessibility_enabled_color` | **Completamente Accessibile** | Ingresso dotato di ascensore funzionante o rampa a norma |
| `entrance_pin_big_accessibility_disabled_color` | **Non Accessibile** | Ingresso con solo gradini / scale fisse, ascensore assente |
| `entrance_pin_big_accessibility_unknown_color` | **Dato Non Disponibile** | Informazione sull'ascensore non garantita dall'agenzia |
| `accessibilityMode.svg` | **Modalità Step-Free Attiva** | Filtro itinerari che esclude scale, trasbordi stretti e pendenze ripide |

---

## 🗣️ 4. Supporto Completo a VoiceOver e Screen Reader

Tutte le etichette dell'interfaccia sono mappate su descrizioni semantiche complete (non solo numeri o sigle):

### Esempi di Etichettatura Sonora:
- **Badge Orario:**
  - *Visivo:* `3 min 🟢`
  - *VoiceOver Spoken:* *"Linea 80, verso Duomo. Partenza tra 3 minuti, tracciamento satellitare confermato."*
- **Indicatore di Affollamento:**
  - *Visivo:* Due silhouette arancioni (`crowding_1`)
  - *VoiceOver Spoken:* *"Affollamento moderato: posti a sedere esauriti, solo posti in piedi disponibili."*
- **Stato di Servizio:**
  - *Visivo:* Triangolo giallo (`alert_warning`)
  - *VoiceOver Spoken:* *"Attenzione: deviazione temporanea sulla linea per lavori stradali su Via Torino."*

---

## 🎚️ 5. Riduzione del Movimento (Reduce Motion)

Quando l'utente attiva l'opzione di sistema "Riduci Movimento" nelle impostazioni di iOS:
1. I pulsanti con rimbalzo (`BounceButtonStyle`) disattivano l'overshoot elastico e passano a un semplice cambio di opacità istantaneo ($1.0 \rightarrow 0.7$).
2. Le onde radio pulsanti del tracciamento GPS live restano fisse.
3. Le animazioni Lottie (`sparkle.json`, `heart-appears.json`) vengono saltate, mostrando direttamente il fotogramma finale della ricompensa.
