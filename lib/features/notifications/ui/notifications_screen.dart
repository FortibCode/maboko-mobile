import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/notification_repository.dart';

/// Notifications reçues par l'utilisateur.
///
/// L'entrée « Notifications » figurait au menu sans aucune action derrière,
/// alors que l'API existait déjà.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _depot = NotificationRepository();

  List<NotificationMaboko>? _notifications;
  int _nonLues = 0;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final resultat = await _depot.lister();
      if (!mounted) return;
      setState(() {
        _notifications = resultat.notifications;
        _nonLues = resultat.nonLues;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    }
  }

  Future<void> _marquerLue(NotificationMaboko notification) async {
    if (notification.lue) return;

    // L'état bascule tout de suite : attendre le serveur donnerait
    // l'impression que la touche n'a pas été prise en compte.
    setState(() {
      _notifications = _notifications
          ?.map((n) => n.id == notification.id ? n.marquerLue() : n)
          .toList();
      _nonLues = (_nonLues - 1).clamp(0, 9999);
    });

    try {
      await _depot.marquerLue(notification.id);
    } on ApiException {
      await _charger();
    }
  }

  Future<void> _toutMarquerLu() async {
    try {
      await _depot.toutMarquerLu();
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_nonLues > 0)
            TextButton(
              onPressed: _toutMarquerLu,
              child: const Text(
                'Tout marquer lu',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: MabokoCouleurs.secondaire,
        onRefresh: _charger,
        child: _corps(),
      ),
    );
  }

  Widget _corps() {
    if (_erreur != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          EtatErreur(message: _erreur!, onReessayer: _charger),
        ],
      );
    }

    if (_notifications == null) return const ChargementEnCours();

    if (_notifications!.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 60),
          EtatVide(
            icone: Icons.notifications_none_rounded,
            titre: 'Aucune notification',
            message: 'Vos alertes sur les devis, les missions et les paiements apparaîtront ici.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications!.length,
      separatorBuilder: (contexte, index) => const Divider(height: 1, indent: 72),
      itemBuilder: (contexte, i) {
        final n = _notifications![i];

        return ListTile(
          onTap: () => _marquerLue(n),
          tileColor: n.lue ? null : MabokoCouleurs.accent.withValues(alpha: 0.07),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _couleurType(n.type).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconeType(n.type), color: _couleurType(n.type), size: 21),
          ),
          title: Text(
            n.titre,
            style: TextStyle(
              fontWeight: n.lue ? FontWeight.w500 : FontWeight.bold,
              fontSize: 14.5,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(n.corps, style: const TextStyle(fontSize: 13, height: 1.35)),
              if (n.recueLe != null) ...[
                const SizedBox(height: 4),
                Text(
                  _depuis(n.recueLe!),
                  style: TextStyle(fontSize: 11, color: context.texteSecondaireMaboko),
                ),
              ],
            ],
          ),
          trailing: n.lue
              ? null
              : Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: MabokoCouleurs.secondaire,
                    shape: BoxShape.circle,
                  ),
                ),
        );
      },
    );
  }

  static IconData _iconeType(String type) => switch (type) {
        'devis' || 'demande' => Icons.description_outlined,
        'mission' => Icons.handyman_outlined,
        'course' => Icons.local_taxi_outlined,
        'paiement' => Icons.payments_outlined,
        'avis' => Icons.star_outline_rounded,
        _ => Icons.notifications_none_rounded,
      };

  static Color _couleurType(String type) => switch (type) {
        'paiement' => MabokoCouleurs.succes,
        'course' => MabokoCouleurs.accent,
        'avis' => MabokoCouleurs.accent,
        _ => MabokoCouleurs.secondaire,
      };

  static String _depuis(DateTime date) {
    final ecart = DateTime.now().difference(date);

    if (ecart.inMinutes < 1) return 'À l’instant';
    if (ecart.inMinutes < 60) return 'Il y a ${ecart.inMinutes} min';
    if (ecart.inHours < 24) return 'Il y a ${ecart.inHours} h';
    if (ecart.inDays < 7) return 'Il y a ${ecart.inDays} j';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
