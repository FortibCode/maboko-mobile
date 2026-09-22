import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/maboko_theme.dart';
import '../core/widgets/etats.dart';

/// Contacts d'urgence du client (§5.1.7).
///
/// Trois numéros joignables en un geste depuis l'application. Stockés
/// uniquement sur le téléphone : ils ne partent jamais au serveur, ce sont
/// des données personnelles sensibles qui n'ont aucune raison d'y être.
class ContactsUrgenceScreen extends StatefulWidget {
  const ContactsUrgenceScreen({super.key});

  @override
  State<ContactsUrgenceScreen> createState() => _ContactsUrgenceScreenState();
}

class _ContactsUrgenceScreenState extends State<ContactsUrgenceScreen> {
  static const _cleContacts = 'contacts_urgence';

  List<ContactUrgence> _contacts = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getStringList(_cleContacts) ?? [];

    if (!mounted) return;
    setState(() {
      _contacts = brut.map(ContactUrgence.depuisChaine).whereType<ContactUrgence>().toList();
      _chargement = false;
    });
  }

  Future<void> _enregistrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cleContacts,
      _contacts.map((c) => c.versChaine()).toList(),
    );
  }

  Future<void> _ajouter() async {
    final contact = await showModalBottomSheet<ContactUrgence>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeuilleContact(),
    );

    if (contact == null) return;

    setState(() => _contacts.add(contact));
    await _enregistrer();
  }

  Future<void> _supprimer(ContactUrgence contact) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirer ce contact ?'),
        content: Text('${contact.nom} ne sera plus joignable en urgence depuis l’application.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer', style: TextStyle(color: MabokoCouleurs.danger)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _contacts.remove(contact));
    await _enregistrer();
  }

  Future<void> _appeler(ContactUrgence contact) async {
    final uri = Uri(scheme: 'tel', path: contact.telephone);

    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de lancer l’appel sur cet appareil.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Contacts d’urgence'),
        backgroundColor: MabokoCouleurs.danger,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        backgroundColor: MabokoCouleurs.danger,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : _contacts.isEmpty
              ? _vide()
              : _liste(),
    );
  }

  Widget _vide() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 60),
        EtatVide(
          icone: Icons.contact_phone_outlined,
          titre: 'Aucun contact d’urgence',
          message: 'Ajoutez jusqu’à 3 personnes à joindre en un geste : '
              'famille, ami proche, ou voisin de confiance.',
        ),
      ],
    );
  }

  Widget _liste() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _contacts.length + 1,
      itemBuilder: (contexte, i) {
        if (i == 0) return _encadre();

        final contact = _contacts[i - 1];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.bordureMaboko),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: MabokoCouleurs.danger.withValues(alpha: 0.12),
              child: const Icon(Icons.person_rounded, color: MabokoCouleurs.danger),
            ),
            title: Text(
              contact.nom,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(contact.telephone, style: const TextStyle(fontSize: 13)),
                if (contact.relation != null && contact.relation!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    contact.relation!,
                    style: TextStyle(fontSize: 11.5, color: context.texteSecondaireMaboko),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: MabokoCouleurs.succes),
                  tooltip: 'Appeler',
                  onPressed: () => _appeler(contact),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: MabokoCouleurs.danger),
                  tooltip: 'Retirer',
                  onPressed: () => _supprimer(contact),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _encadre() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MabokoCouleurs.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MabokoCouleurs.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: MabokoCouleurs.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ces contacts restent uniquement sur votre téléphone. '
              'Ils ne sont jamais envoyés à Maboko ni partagés avec qui que ce soit.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.texteSecondaireMaboko,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------------------

/// Contact d'urgence, stocké en local sous forme `nom|telephone|relation`.
class ContactUrgence {
  const ContactUrgence({required this.nom, required this.telephone, this.relation});

  final String nom;
  final String telephone;
  final String? relation;

  String versChaine() => '$nom|$telephone|${relation ?? ''}';

  static ContactUrgence? depuisChaine(String brut) {
    final morceaux = brut.split('|');
    if (morceaux.length < 2 || morceaux[0].isEmpty) return null;

    return ContactUrgence(
      nom: morceaux[0],
      telephone: morceaux[1],
      relation: morceaux.length > 2 && morceaux[2].isNotEmpty ? morceaux[2] : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Formulaire d'ajout (feuille du bas)
// ---------------------------------------------------------------------------

class _FeuilleContact extends StatefulWidget {
  const _FeuilleContact();

  @override
  State<_FeuilleContact> createState() => _FeuilleContactState();
}

class _FeuilleContactState extends State<_FeuilleContact> {
  final _cleFormulaire = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _relation = TextEditingController();

  @override
  void dispose() {
    _nom.dispose();
    _telephone.dispose();
    _relation.dispose();
    super.dispose();
  }

  void _valider() {
    if (!_cleFormulaire.currentState!.validate()) return;

    Navigator.pop(
      context,
      ContactUrgence(
        nom: _nom.text.trim(),
        telephone: _telephone.text.trim(),
        relation: _relation.text.trim().isEmpty ? null : _relation.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final basClavier = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: basClavier),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _cleFormulaire,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.bordureMaboko,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Nouveau contact d’urgence',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nom,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Nom complet', Icons.person_outline_rounded),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Indiquez un nom.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telephone,
                keyboardType: TextInputType.phone,
                decoration: _decoration('Numéro de téléphone', Icons.phone_outlined,
                    indice: 'Ex. : +242 06 123 45 67'),
                validator: (v) {
                  final propre = (v ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
                  return propre.length < 6 ? 'Numéro invalide.' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relation,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('Relation (facultatif)', Icons.people_outline_rounded,
                    indice: 'Ex. : Maman, voisin, ami'),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _valider,
                  style: FilledButton.styleFrom(
                    backgroundColor: MabokoCouleurs.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Enregistrer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String libelle, IconData icone, {String? indice}) {
    return InputDecoration(
      labelText: libelle,
      hintText: indice,
      prefixIcon: Icon(icone, size: 20, color: MabokoCouleurs.danger),
      filled: true,
      fillColor: context.surfaceMaboko,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.bordureMaboko),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.bordureMaboko),
      ),
    );
  }
}