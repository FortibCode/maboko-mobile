import 'package:flutter/material.dart';

/// Carte qui s'enfonce légèrement sous le doigt.
///
/// Un `InkWell` ne donne qu'une onde de couleur ; sur une carte posée sur un
/// fond clair elle se voit à peine. Un léger retrait donne la sensation
/// physique d'un appui, comme dans les applications soignées.
class CartePressable extends StatefulWidget {
  const CartePressable({
    super.key,
    required this.child,
    required this.onTap,
    this.echelle = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double echelle;

  @override
  State<CartePressable> createState() => _CartePressableState();
}

class _CartePressableState extends State<CartePressable> {
  bool _enfonce = false;

  void _changer(bool valeur) {
    if (widget.onTap == null || _enfonce == valeur) return;
    setState(() => _enfonce = valeur);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _changer(true),
      onTapUp: (_) => _changer(false),
      onTapCancel: () => _changer(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _enfonce ? widget.echelle : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Apparition en fondu et en glissé, décalée selon le rang.
///
/// Une liste qui surgit d'un bloc paraît brutale ; un décalage de quelques
/// dizaines de millisecondes par élément donne l'impression que le contenu
/// se pose.
class ApparitionDecalee extends StatefulWidget {
  const ApparitionDecalee({
    super.key,
    required this.child,
    this.rang = 0,
    this.decalage = const Duration(milliseconds: 55),
  });

  final Widget child;
  final int rang;
  final Duration decalage;

  @override
  State<ApparitionDecalee> createState() => _ApparitionDecaleeState();
}

class _ApparitionDecaleeState extends State<ApparitionDecalee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void initState() {
    super.initState();

    // Au-delà d'une dizaine d'éléments le décalage cumulé deviendrait une
    // attente : on le plafonne.
    final attente = widget.decalage * widget.rang.clamp(0, 10);
    Future.delayed(attente, () {
      if (mounted) _controleur.forward();
    });
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courbe = CurvedAnimation(parent: _controleur, curve: Curves.easeOutCubic);

    return FadeTransition(
      opacity: courbe,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(courbe),
        child: widget.child,
      ),
    );
  }
}
