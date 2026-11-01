import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/maboko_theme.dart';
import '../data/course_repository.dart';

class DemandesChauffeurScreen extends StatefulWidget {
  final Map<String, dynamic> courseData; // Les données de la course
  const DemandesChauffeurScreen({super.key, required this.courseData});

  @override
  State<DemandesChauffeurScreen> createState() => _DemandesChauffeurScreenState();
}

class _DemandesChauffeurScreenState extends State<DemandesChauffeurScreen> {
  final _prixController = TextEditingController();
  bool _envoi = false;

  Future<void> _accepter() async {
    setState(() => _envoi = true);
    try {
      await const CourseRepository().accepterCourse(widget.courseData['id']);
      if (!mounted) return;
      Navigator.pop(context); // Retour à la liste
    } catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _contreProposer() async {
    if (_prixController.text.isEmpty) return;
    setState(() => _envoi = true);
    try {
      await const CourseRepository().contreProposer(
        widget.courseData['id'], 
        double.parse(_prixController.text)
      );
      if (!mounted) return;
      Navigator.pop(context); // Le client doit maintenant accepter
    } catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prixClient = widget.courseData['prix_client'] ?? widget.courseData['tarif_estime'];
    final depart = widget.courseData['lieu_depart'] ?? 'Départ';
    final arrivee = widget.courseData['lieu_arrivee'] ?? 'Arrivée';

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle course')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$depart ➡️ $arrivee', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Le client propose : ${prixClient} FCFA', style: const TextStyle(fontSize: 16, color: MabokoCouleurs.secondaire)),
            const SizedBox(height: 32),
            
            TextField(
              controller: _prixController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Proposer un autre prix (FCFA)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _envoi ? null : _contreProposer,
                child: const Text('Envoyer ma proposition'),
              ),
            ),
            
            const Spacer(),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await const CourseRepository().refuserCourse(widget.courseData['id']);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _envoi ? null : _accepter,
                    style: FilledButton.styleFrom(backgroundColor: MabokoCouleurs.succes),
                    child: const Text('Accepter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}