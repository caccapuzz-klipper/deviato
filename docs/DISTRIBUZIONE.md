# Guida all'installazione su iPhone (Sideloadly / AltStore)

Questa guida spiega come scaricare e installare l'applicazione **DeviaTo** (`.ipa`) sul tuo iPhone senza passare dall'App Store, usando un computer (Windows o Mac) e un normale account Apple ID gratuito.

---

## 1. Come scaricare il file `.ipa`

L'applicazione viene compilata automaticamente tramite GitHub Actions sui server macOS di GitHub:

1. Apri la pagina del repository: [github.com/caccapuzz-klipper/deviato](https://github.com/caccapuzz-klipper/deviato)
2. Vai nella scheda **Actions** in alto.
3. Seleziona il workflow **"Compila iOS (.ipa non firmato)"** nella colonna di sinistra.
4. Clicca su **Run workflow** (pulsante a destra) selezionando il ramo `main`.
5. Attendi il completamento della compilazione (circa 8–12 minuti).
6. Al termine del job, scorri in basso nella pagina della corsa e troverai la sezione **Artifacts**: scarica il file **`Deviato-unsigned-ipa.zip`**.
7. Estrai lo zip: troverai il file `Deviato-unsigned.ipa`.

---

## 2. Installazione tramite Sideloadly (Consigliato su Windows)

**Sideloadly** è il metodo più semplice e rapido per installare un file `.ipa` firmandolo con il proprio Apple ID.

### Prerequisiti su Windows:
- Scarica e installa **iTunes** (versione standalone Apple, non da Microsoft Store): [Supporto Apple iTunes](https://support.apple.com/it-it/HT210384)
- Scarica e installa **iCloud** (versione standalone Apple): [Supporto Apple iCloud](https://support.apple.com/it-it/HT204283)
- Scarica e installa **Sideloadly**: [sideloadly.io](https://sideloadly.io/)

### Procedura:
1. Collega l'iPhone al PC con il cavo USB e sblocca lo schermo (se richiesto, seleziona "Autorizza questo computer").
2. Apri **Sideloadly**.
3. Verifica che il tuo iPhone compaia nel campo **Device**.
4. Trascina il file `Deviato-unsigned.ipa` dentro il riquadro dell'icona IPA in Sideloadly.
5. Nel campo **Apple ID**, inserisci la tua email dell'Apple ID (quella usata su quell'iPhone o un account Apple secondario).
6. Clicca su **Start**. Se richiesto, inserisci la password dell'Apple ID e il codice a due fattori a 6 cifre che compare sull'iPhone.
7. Sideloadly firmerà e installerà l'app sull'iPhone in circa 30–60 secondi.

---

## 3. Primo avvio sull'iPhone (Autorizzazione sviluppatore)

La prima volta che tocchi l'icona di DeviaTo sull'iPhone comparirà l'avviso *"Sviluppatore interno non attendibile"*. È normale per tutte le app installate privatamente via sideloading:

1. Apri **Impostazioni** sull'iPhone.
2. Vai su **Generali** › **VPN e gestione dispositivo**.
3. Sotto **App sviluppatore**, tocca la voce con il tuo indirizzo email Apple ID.
4. Tocca **"Autorizza [tua-email]"** e conferma con **Autorizza**.
5. *(Solo su iOS 16 e successivi)*: Vai su **Impostazioni** › **Privacy e sicurezza** › scorri fino in fondo su **Modalità sviluppatore**, attivala e riavvia l'iPhone se richiesto.

L'applicazione è ora pronta all'uso!

---

## 4. Scadenza dei 7 giorni e rinnovo

Gli Apple ID gratuiti permettono di firmare applicazioni per uso personale con validità di **7 giorni**:

- Dopo 7 giorni l'app non si aprirà più (dirà che il certificato è scaduto).
- I tuoi dati e le tue fermate preferite **non vanno persi**.
- Per rinnovare l'app: ricollega l'iPhone al PC, apri Sideloadly e ripeti il passaggio (premi di nuovo Start con lo stesso IPA).
- Se lasci Sideloadly aperto sul PC nella stessa rete Wi-Fi (o se usi AltStore con AltServer), l'app può rinnovarsi automaticamente via Wi-Fi prima della scadenza.
