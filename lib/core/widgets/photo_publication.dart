import 'package:flutter/material.dart';

import '../theme/maboko_theme.dart';

/// Photo d'une publication, affichée dans ses proportions réelles.
///
/// Le fil imposait à toute image une boîte de 320 pixels de haut en mode
/// « cover ». Une photo de réalisation prise à la verticale — le cas courant
/// pour une porte, un mur, un meuble — perdait ainsi plus de quarante pour
/// cent de sa hauteur, coupée en haut et en bas. L'artisan montrait son
/// travail, le client en voyait une tranche.
///
/// Les proportions sont bornées : une photo très allongée occuperait sinon
/// deux écrans dans le fil. Au-delà des bornes, l'image est contenue sur un
/// fond neutre plutôt que rognée.
class PhotoPublication extends StatefulWidget {
  const PhotoPublication({
    super.key,
    required this.url,
    this.rapportMin = 0.8,
    this.rapportMax = 16 / 9,
    this.onTap,
  });

  final String url;

  /// Portrait le plus haut accepté (4:5).
  final double rapportMin;

  /// Paysage le plus large accepté (16:9).
  final double rapportMax;

  final VoidCallback? onTap;

  @override
  State<PhotoPublication> createState() => _PhotoPublicationState();
}

class _PhotoPublicationState extends State<PhotoPublication> {
  ImageStream? _flux;
  ImageStreamListener? _ecouteur;

  double? _rapportReel;
  bool _erreur = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resoudre();
  }

  @override
  void didUpdateWidget(PhotoPublication ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.url != widget.url) {
      _rapportReel = null;
      _erreur = false;
      _resoudre();
    }
  }

  /// Interroge les dimensions de l'image avant de lui réserver sa place.
  void _resoudre() {
    _detacher();

    final fournisseur = NetworkImage(widget.url);
    final flux = fournisseur.resolve(createLocalImageConfiguration(context));

    final ecouteur = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() => _rapportReel = info.image.width / info.image.height);
      },
      onError: (erreur, trace) {
        if (!mounted) return;
        setState(() => _erreur = true);
      },
    );

    flux.addListener(ecouteur);
    _flux = flux;
    _ecouteur = ecouteur;
  }

  void _detacher() {
    if (_flux != null && _ecouteur != null) _flux!.removeListener(_ecouteur!);
    _flux = null;
    _ecouteur = null;
  }

  @override
  void dispose() {
    _detacher();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_erreur) return _cadre(child: _placeholder(Icons.broken_image_outlined));

    final reel = _rapportReel;

    // Tant que les dimensions sont inconnues, on réserve une place au format
    // le plus courant plutôt que de faire sauter la liste à l'arrivée.
    if (reel == null) {
      return _cadre(
        rapport: widget.rapportMin,
        child: _placeholder(null),
      );
    }

    final borne = reel.clamp(widget.rapportMin, widget.rapportMax);
    // Hors bornes : l'image est contenue, jamais coupée.
    final ajustement = borne == reel ? BoxFit.cover : BoxFit.contain;

    return _cadre(
      rapport: borne,
      child: Image.network(
        widget.url,
        fit: ajustement,
        errorBuilder: (contexte, erreur, trace) => _placeholder(Icons.broken_image_outlined),
      ),
    );
  }

  Widget _cadre({required Widget child, double? rapport}) {
    final contenu = AspectRatio(
      aspectRatio: rapport ?? widget.rapportMin,
      child: Container(
        color: context.teinteMaboko,
        width: double.infinity,
        child: child,
      ),
    );

    if (widget.onTap == null) return contenu;

    return GestureDetector(onTap: widget.onTap, child: contenu);
  }

  Widget _placeholder(IconData? icone) {
    return Center(
      child: icone == null
          ? const CircularProgressIndicator(
              color: MabokoCouleurs.secondaire,
              strokeWidth: 2,
            )
          : Icon(icone, size: 40, color: context.bordureMaboko),
    );
  }
}
