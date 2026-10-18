import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_repository.dart';
import 'apple_theme.dart';
import 'cartina.dart';
import 'logo.dart';

/// Da dove vengono i dati, cosa sono, e cosa non sono.
///
/// Era la schermata delle impostazioni, con la chiave del modello e il
/// pulsante per riscaricare gli orari. Da quando il calcolo lo fa il job su
/// GitHub non c'e' piu' niente da impostare: restano le cose che chi usa
/// l'app deve poter sapere, e che la licenza di GTT chiede di dire.
class InfoScreen extends StatelessWidget {
  const InfoScreen({required this.repo, super.key});

  final AppRepository repo;

  @override
  Widget build(BuildContext context) {
    final generato = repo.generato;
    final feed = repo.feed;

    return Scaffold(
      backgroundColor: AppleColors.systemGroupedBackground(context),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppleColors.systemBackground(context).withValues(alpha: 0.85),
        title: Text(
          'Informazioni',
          style: AppleTypography.headline(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          AppSection(
            header: 'Da sapere',
            children: const [
              _Paragrafo(
                'DeviaTo non è un\'app di GTT e non è collegata a GTT. Le '
                'fermate non servite e i percorsi deviati sono ricavati in '
                'automatico dagli avvisi e possono contenere errori: in caso di '
                'dubbio fa fede l\'avviso originale, che trovi sempre nel '
                'dettaglio della linea.',
              ),
            ],
          ),

          AppSection(
            header: 'Da dove vengono i dati',
            footer: (generato != null || feed != null)
                ? [
                    if (generato != null) 'Dati aggiornati alle ${_ora(generato)}',
                    if (feed != null) 'Orari GTT del ${_feed(feed)}',
                  ].join(' · ')
                : null,
            children: [
              const _Paragrafo(
                'Avvisi, percorsi, fermate, orari e posizioni dei mezzi sono dati '
                'aperti di GTT (licenza CC BY 4.0). Gli avvisi vengono elaborati '
                'per ricavarne i percorsi deviati e le fermate non servite. '
                'Il calendario scioperi è tratto dalle proclamazioni ufficiali '
                'del Ministero delle Infrastrutture e dei Trasporti.',
              ),
              _Collegamento(
                icona: CupertinoIcons.bus,
                titolo: 'Data source: GTT S.p.A. – Gruppo Torinese Trasporti',
                dettaglio: 'www.gtt.to.it',
                indirizzo: 'https://www.gtt.to.it',
                seNonSiApre: 'Impossibile aprire il sito di GTT.',
              ),
              _Collegamento(
                icona: CupertinoIcons.calendar_today,
                titolo: 'Calendario scioperi MIT',
                dettaglio: 'scioperi.mit.gov.it',
                indirizzo: 'https://scioperi.mit.gov.it/mit2/public/scioperi',
                seNonSiApre: 'Impossibile aprire il calendario MIT.',
              ),
            ],
          ),

          AppSection(
            header: 'Privacy',
            children: const [
              _Paragrafo(
                'L\'app non raccoglie dati personali e non ha un account. La tua '
                'posizione, se la attivi sulla mappa, resta sul telefono.',
              ),
              _Collegamento(
                icona: CupertinoIcons.shield_fill,
                titolo: 'Informativa sulla privacy',
                dettaglio: 'deviato.it/privacy',
                indirizzo: 'https://deviato.it/privacy.html',
                seNonSiApre: 'Impossibile aprire l\'informativa.',
              ),
            ],
          ),

          AppSection(
            header: 'DeviaTo',
            children: const [
              _Collegamento(
                icona: CupertinoIcons.globe,
                titolo: 'Sito',
                dettaglio: 'deviato.it',
                indirizzo: 'https://deviato.it',
                seNonSiApre: 'Impossibile aprire il sito.',
              ),
              _Collegamento(
                icona: CupertinoIcons.mail,
                titolo: 'Segnala un errore o scrivici',
                dettaglio: 'devia.to@icloud.com',
                indirizzo: 'mailto:devia.to@icloud.com?subject=DeviaTo',
                seNonSiApre: 'Nessuna app per la posta. Scrivi a devia.to@icloud.com.',
              ),
              _Collegamento(
                icona: CupertinoIcons.chevron_left_slash_chevron_right,
                titolo: 'Codice su GitHub',
                dettaglio: 'github.com/TCdesign-dev/deviato',
                indirizzo: 'https://github.com/TCdesign-dev/deviato',
                seNonSiApre: 'Impossibile aprire GitHub.',
              ),
            ],
          ),

          AppSection(
            header: 'Crediti',
            children: [
              _Paragrafo(
                'Mappe © contributori di OpenStreetMap'
                '${Cartina.carto ? ', immagini della cartina © CARTO' : ''}. '
                'Percorsi calcolati con Valhalla (FOSSGIS), indirizzi con Photon.',
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 20),
            child: Column(
              children: [
                const DeviatoLogo(height: 28),
                const SizedBox(height: 8),
                Text(
                  '© ${DateTime.now().year} DeviaTo',
                  style: AppleTypography.footnote(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _ora(DateTime t) {
    final h =
        '${t.hour.toString().padLeft(2, "0")}:'
        '${t.minute.toString().padLeft(2, "0")}';
    final oggi = DateTime.now();
    final stessoGiorno =
        t.year == oggi.year && t.month == oggi.month && t.day == oggi.day;
    return stessoGiorno ? h : '$h del ${t.day}/${t.month}';
  }

  /// «20260922» → «22/09/2026».
  static String _feed(String f) => f.length == 8
      ? '${f.substring(6)}/${f.substring(4, 6)}/${f.substring(0, 4)}'
      : f;
}

class _Paragrafo extends StatelessWidget {
  const _Paragrafo(this.testo);

  final String testo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      testo,
      style: AppleTypography.callout(context).copyWith(height: 1.35),
    ),
  );
}

/// Una riga che apre un indirizzo: un sito, o la posta.
class _Collegamento extends StatelessWidget {
  const _Collegamento({
    required this.icona,
    required this.titolo,
    required this.dettaglio,
    required this.indirizzo,
    required this.seNonSiApre,
  });

  final IconData icona;
  final String titolo;
  final String dettaglio;
  final String indirizzo;

  /// Cosa dire se il telefono non sa aprirlo: nessun browser, nessuna app
  /// per la posta.
  final String seNonSiApre;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        var aperto = false;
        try {
          aperto = await launchUrl(
            Uri.parse(indirizzo),
            mode: LaunchMode.externalApplication,
          );
        } on Object {
          aperto = false;
        }
        if (!aperto) {
          messenger.showSnackBar(SnackBar(content: Text(seNonSiApre)));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppleColors.systemBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icona, size: 16, color: AppleColors.systemBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titolo,
                    style: AppleTypography.callout(context).copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    dettaglio,
                    style: AppleTypography.footnote(context),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey3),
          ],
        ),
      ),
    );
  }
}
