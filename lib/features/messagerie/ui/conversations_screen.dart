import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/messagerie_repository.dart';
import '../models/conversation.dart';
import 'conversation_screen.dart';

/// Liste des conversations en cours avec les artisans contactés et le
/// support Maboko (§5.1.9).
///
/// Remplace le libellé « Page Messages ».
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  static const _repository = MessagerieRepository();

  List<Conversation> _conversations = const [];
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final conversations = await _repository.conversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _chargement = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    }
  }

  Future<void> _ouvrir(Conversation conversation) async {
    setState(() => conversation.nonLus = 0);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConversationScreen(conversation: conversation)),
    );

    await _charger();
  }

  Future<void> _ouvrirSupport() async {
    try {
      final conversation = await _repository.support();
      if (!mounted) return;
      await _ouvrir(conversation);
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
      backgroundColor: MabokoCouleurs.fond,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_rounded),
            tooltip: 'Contacter le support Maboko',
            onPressed: _ouvrirSupport,
          ),
        ],
      ),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null && _conversations.isEmpty) {
      return EtatErreur(message: _erreur!, onReessayer: _charger);
    }

    if (_conversations.isEmpty) {
      return RefreshIndicator(
        color: MabokoCouleurs.secondaire,
        onRefresh: _charger,
        child: ListView(
          children: [
            SizedBox(
              height: 400,
              child: EtatVide(
                icone: Icons.chat_bubble_outline,
                titre: 'Aucune conversation',
                message: 'Contactez un artisan depuis son profil pour démarrer '
                    'un échange sur votre demande.',
                action: OutlinedButton.icon(
                  onPressed: _ouvrirSupport,
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('Écrire au support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MabokoCouleurs.secondaire,
                    side: const BorderSide(color: MabokoCouleurs.secondaire),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: MabokoCouleurs.secondaire,
      onRefresh: _charger,
      child: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
        itemBuilder: (context, i) => _ligne(_conversations[i]),
      ),
    );
  }

  Widget _ligne(Conversation conversation) {
    final aDuNonLu = conversation.nonLus > 0;

    return ListTile(
      tileColor: MabokoCouleurs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: MabokoCouleurs.fond,
        backgroundImage: conversation.interlocuteur.avatarUrl?.isNotEmpty == true
            ? NetworkImage(conversation.interlocuteur.avatarUrl!)
            : null,
        child: conversation.interlocuteur.avatarUrl?.isNotEmpty == true
            ? null
            : Icon(
                conversation.estSupport ? Icons.support_agent_rounded : Icons.handyman_rounded,
                color: MabokoCouleurs.secondaire,
              ),
      ),
      title: Text(
        conversation.interlocuteur.nomComplet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: aDuNonLu ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        conversation.dernierMessage ?? 'Conversation ouverte',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: aDuNonLu ? MabokoCouleurs.principale : MabokoCouleurs.texteSecondaire,
          fontWeight: aDuNonLu ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            horodatageCourt(conversation.dernierMessageLe),
            style: const TextStyle(fontSize: 11, color: MabokoCouleurs.texteSecondaire),
          ),
          const SizedBox(height: 6),
          if (aDuNonLu)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(
                color: MabokoCouleurs.secondaire,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.nonLus}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: () => _ouvrir(conversation),
    );
  }
}

/// Horodatage court : l'heure aujourd'hui, « hier », puis la date.
String horodatageCourt(DateTime? date) {
  if (date == null) return '';

  final maintenant = DateTime.now();
  final local = date.toLocal();
  final jour = DateTime(local.year, local.month, local.day);
  final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
  final ecart = aujourdhui.difference(jour).inDays;

  if (ecart == 0) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  if (ecart == 1) return 'hier';

  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
}
