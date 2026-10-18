import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/deviation_service.dart';
import '../core/models/notice.dart';
import '../core/pipeline/closure_summary.dart';
import 'apple_theme.dart';
import 'quando_avviso.dart';
import 'riassunto.dart';

/// La scheda che galleggia in basso sulla mappa a tutto schermo.
///
/// Prima era un pannello attaccato al bordo, largo tutto lo schermo, che
/// si trascinava: pesante, e le fermate non servite stavano dietro «Più
/// dettagli». Gli avvisi non c'erano. Ora e' una scheda staccata dai
/// bordi, alta quanto il suo contenuto — fino a quasi meta' schermo, poi
/// scorre dentro — con tre pagine: Riepilogo, Fermate, Avvisi. Si passa
/// dall'una all'altra toccando le etichette in cima o scorrendo di lato:
/// lo scorrimento non lo conoscono tutti, le etichette si' (Tommaso,
/// 30/09/2026). Le pagine senza contenuto non ci sono, e con una sola le
/// etichette spariscono.
///
/// Toccando una fermata sulla mappa la scheda mostra quella ([fermata]),
/// e chiudendola torna alle pagine.
///
/// In fondo, sempre, i comandi della mappa ([comandi]): prima galleggiavano
/// sulla cartina e la coprivano. E la scheda si riduce verso il basso —
/// dalla freccia accanto alle etichette, o trascinandola giu' — a una riga
/// con lo stato della linea piu' i comandi, per guardare la mappa quasi
/// intera (Tommaso, 01/10/2026).
class SchedaMappa extends StatefulWidget {
  const SchedaMappa({
    required this.status,
    required this.riepilogo,
    this.soloDirezione,
    this.onTratto,
    this.fermata,
    this.comandi,
    this.onAltezza,
    super.key,
  });

  final LineStatus status;

  /// Cosa sta sotto lo stato nella prima pagina: la legenda.
  final Widget riepilogo;

  /// Solo la direzione di questo percorso (shapeId).
  final String? soloDirezione;

  final ValueChanged<ClosedRun>? onTratto;

  /// La fermata toccata, al posto delle pagine.
  final Widget? fermata;

  /// I comandi della mappa, in fondo alla scheda.
  final Widget? comandi;

  /// Quanto e' alta la scheda, a ogni cambio: la mappa le fa posto.
  final ValueChanged<double>? onAltezza;

  @override
  State<SchedaMappa> createState() => _SchedaMappaState();
}

enum _Pagina { riepilogo, fermate, avvisi }

class _SchedaMappaState extends State<SchedaMappa> {
  var _pagina = _Pagina.riepilogo;

  /// Da che parte entra la pagina nuova: 1 da destra, -1 da sinistra.
  var _verso = 1;

  /// Ridotta: solo lo stato della linea e i comandi.
  var _ridotta = false;

  /// L'ultimo cambio e' stato fra due pagine: solo allora il contenuto
  /// scorre di lato. Riducendo la scheda o toccando una fermata sfuma.
  var _diLato = false;

  List<_Pagina> get _pagine => [
    _Pagina.riepilogo,
    if (RiassuntoLinea.conTratti(
      widget.status,
      soloDirezione: widget.soloDirezione,
    ))
      _Pagina.fermate,
    if (widget.status.reports.isNotEmpty) _Pagina.avvisi,
  ];

  @override
  void didUpdateWidget(SchedaMappa old) {
    super.didUpdateWidget(old);
    if ((old.fermata == null) != (widget.fermata == null)) _diLato = false;
  }

  void _vai(_Pagina p) {
    if (p == _pagina) return;
    final pagine = _pagine;
    setState(() {
      _verso = pagine.indexOf(p) > pagine.indexOf(_pagina) ? 1 : -1;
      _pagina = p;
      _diLato = true;
    });
  }

  void _scorri(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 250) return;
    final pagine = _pagine;
    final i = pagine.indexOf(_pagina) + (v < 0 ? 1 : -1);
    if (i >= 0 && i < pagine.length) _vai(pagine[i]);
  }

  void _riduci(bool ridotta) {
    if (ridotta == _ridotta) return;
    setState(() {
      _ridotta = ridotta;
      _diLato = false;
    });
  }

  /// Trascinando in giu' si riduce, in su si riapre.
  void _trascina(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() >= 250) _riduci(v > 0);
  }

  @override
  Widget build(BuildContext context) {
    final pagine = _pagine;
    // Una pagina sparita (un avviso tolto, un'altra direzione scelta):
    // si torna al riepilogo.
    final pagina = pagine.contains(_pagina) ? _pagina : _Pagina.riepilogo;
    final massima = MediaQuery.sizeOf(context).height * 0.45;
    // Con una pagina sola non c'e' niente da ridurre: e' gia' corta.
    final ridotta = _ridotta && pagine.length > 1 && widget.fermata == null;

    final Widget contenuto;
    if (widget.fermata != null) {
      contenuto = KeyedSubtree(
        key: const ValueKey('fermata'),
        child: widget.fermata!,
      );
    } else if (ridotta) {
      contenuto = KeyedSubtree(
        key: const ValueKey('ridotta'),
        child: _Ridotta(
          status: widget.status,
          soloDirezione: widget.soloDirezione,
          onApri: () => _riduci(false),
        ),
      );
    } else {
      contenuto = KeyedSubtree(
        key: ValueKey(pagina),
        child: switch (pagina) {
          _Pagina.riepilogo => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RiassuntoLinea(
                status: widget.status,
                soloDirezione: widget.soloDirezione,
                parte: ParteRiassunto.titolo,
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              ),
              widget.riepilogo,
            ],
          ),
          _Pagina.fermate => RiassuntoLinea(
            status: widget.status,
            soloDirezione: widget.soloDirezione,
            onTratto: widget.onTratto,
            parte: ParteRiassunto.tratti,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          ),
          _Pagina.avvisi => _Avvisi(status: widget.status),
        },
      );
    }
    final inPagina = widget.fermata == null && !ridotta;

    return _Misura(
      onMisura: (s) => widget.onAltezza?.call(s.height),
      child: Container(
        decoration: BoxDecoration(
          color: AppleColors.secondarySystemGroupedBackground(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppleColors.separator(context),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (inPagina && pagine.length > 1)
                GestureDetector(
                  onVerticalDragEnd: _trascina,
                  child: _Etichette(
                    pagine: pagine,
                    scelta: pagina,
                    avvisi: _Avvisi.quanti(widget.status),
                    onScelta: _vai,
                    onRiduci: () => _riduci(true),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: massima),
                child: GestureDetector(
                  onHorizontalDragEnd: inPagina ? _scorri : null,
                  onVerticalDragEnd: ridotta ? _trascina : null,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    layoutBuilder: (attuale, precedenti) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...precedenti, ?attuale],
                    ),
                    transitionBuilder: (figlio, animazione) {
                      final sfuma = FadeTransition(
                        opacity: animazione,
                        child: figlio,
                      );
                      if (!_diLato) return sfuma;
                      final entra = figlio.key == ValueKey(pagina);
                      return SlideTransition(
                        position: Tween(
                          begin: Offset(
                            entra ? 0.25 * _verso : -0.25 * _verso,
                            0,
                          ),
                          end: Offset.zero,
                        ).animate(animazione),
                        child: sfuma,
                      );
                    },
                    child: SingleChildScrollView(
                      key: contenuto.key,
                      padding: EdgeInsets.only(bottom: inPagina ? 6 : 0),
                      child: contenuto,
                    ),
                  ),
                ),
              ),
              if (widget.comandi != null) ...[
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: AppleColors.separator(context),
                ),
                widget.comandi!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// La scheda ridotta: lo stato della linea su una riga, e «Dettagli» per
/// riaprirla. Tutta la riga si tocca.
class _Ridotta extends StatelessWidget {
  const _Ridotta({
    required this.status,
    required this.soloDirezione,
    required this.onApri,
  });

  final LineStatus status;
  final String? soloDirezione;
  final VoidCallback onApri;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mostra i dettagli',
      child: InkWell(
        onTap: onApri,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: RiassuntoLinea(
                  status: status,
                  soloDirezione: soloDirezione,
                  parte: ParteRiassunto.stato,
                  margin: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                ),
              ),
              Text(
                'Dettagli',
                style: AppleTypography.subheadline(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppleColors.secondaryLabel(context),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_up,
                size: 14,
                color: AppleColors.secondaryLabel(context),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le etichette delle pagine, in cima alla scheda.
class _Etichette extends StatelessWidget {
  const _Etichette({
    required this.pagine,
    required this.scelta,
    required this.avvisi,
    required this.onScelta,
    required this.onRiduci,
  });

  final List<_Pagina> pagine;
  final _Pagina scelta;
  final int avvisi;
  final ValueChanged<_Pagina> onScelta;

  /// La freccia in fondo alla riga: riduce la scheda.
  final VoidCallback onRiduci;

  @override
  Widget build(BuildContext context) {
    String nome(_Pagina p) => switch (p) {
      _Pagina.riepilogo => 'Riepilogo',
      _Pagina.fermate => 'Fermate',
      _Pagina.avvisi => avvisi > 1 ? 'Avvisi · $avvisi' : 'Avviso',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppleColors.tertiarySystemGroupedBackground(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  for (final p in pagine)
                    Expanded(
                      child: Semantics(
                        selected: p == scelta,
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onScelta(p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p == scelta
                                  ? AppleColors.secondarySystemGroupedBackground(context)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: p == scelta
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              nome(p),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppleTypography.footnote(context).copyWith(
                                fontWeight: p == scelta ? FontWeight.w600 : FontWeight.w500,
                                color: p == scelta
                                    ? AppleColors.label(context)
                                    : AppleColors.secondaryLabel(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRiduci,
            tooltip: 'Riduci la scheda',
            icon: Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: AppleColors.secondaryLabel(context),
            ),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Gli avvisi di GTT della linea, uno per riquadro: titolo, date, le
/// prime righe e il testo completo a richiesta. Lo stesso avviso vale
/// spesso per due direzioni: si mostra una volta.
class _Avvisi extends StatelessWidget {
  const _Avvisi({required this.status});

  final LineStatus status;

  /// Prima quelli in corso, poi quelli di altri giorni od orari, poi
  /// quelli in programma, e in fondo quelli finiti che GTT non ha tolto.
  static List<RawNotice> _di(LineStatus status) {
    final visti = <String>{};
    return [
      for (final gruppo in [
        status.activeReports,
        status.otherTimeReports,
        status.scheduledReports,
        status.endedReports,
      ])
        for (final r in gruppo)
          if (visti.add(r.notice.id)) r.notice,
    ];
  }

  static int quanti(LineStatus status) => _di(status).length;

  @override
  Widget build(BuildContext context) {
    final avvisi = _di(status);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < avvisi.length; i++) ...[
          if (i > 0)
            Divider(
              height: 0.5,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              color: AppleColors.separator(context),
            ),
          _Avviso(notice: avvisi[i], ora: status.checkedAt),
        ],
      ],
    );
  }
}

class _Avviso extends StatefulWidget {
  const _Avviso({required this.notice, required this.ora});

  final RawNotice notice;
  final DateTime ora;

  @override
  State<_Avviso> createState() => _AvvisoState();
}

class _AvvisoState extends State<_Avviso> {
  var _aperto = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notice;
    // I testi del feed hanno doppi spazi a caso: le parole restano quelle.
    final corpo = n.text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    final titolo = n.headline != null && n.headline!.trim().isNotEmpty
        ? n.headline!.trim()
        : null;
    final quando = quandoAvviso(n, widget.ora);
    final lungo = corpo.length > 160;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titolo != null)
            Text(
              titolo,
              style: AppleTypography.subheadline(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (quando.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                quando,
                style: AppleTypography.caption1(context).copyWith(
                  color: AppleColors.secondaryLabel(context),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            corpo,
            maxLines: _aperto || !lungo ? null : 3,
            overflow: _aperto || !lungo ? null : TextOverflow.ellipsis,
            style: AppleTypography.subheadline(context),
          ),
          if (lungo)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: Size.zero,
              alignment: Alignment.centerLeft,
              onPressed: () => setState(() => _aperto = !_aperto),
              child: Text(
                _aperto ? 'Mostra meno' : 'Testo completo',
                style: AppleTypography.footnote(context).copyWith(
                  color: AppleColors.systemBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Dice quanto e' grande il figlio, ogni volta che cambia.
class _Misura extends SingleChildRenderObjectWidget {
  const _Misura({required this.onMisura, required super.child});

  final ValueChanged<Size> onMisura;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMisura(onMisura);

  @override
  void updateRenderObject(BuildContext context, _RenderMisura render) =>
      render.onMisura = onMisura;
}

class _RenderMisura extends RenderProxyBox {
  _RenderMisura(this.onMisura);

  ValueChanged<Size> onMisura;
  Size? _vecchia;

  @override
  void performLayout() {
    super.performLayout();
    final s = size;
    if (s == _vecchia) return;
    _vecchia = s;
    WidgetsBinding.instance.addPostFrameCallback((_) => onMisura(s));
  }
}
