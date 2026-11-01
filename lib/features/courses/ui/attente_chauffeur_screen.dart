import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/network/api.dart';
import '../../../core/theme/maboko_theme.dart';
import '../data/course_repository.dart';
import '../models/course.dart';
import 'suivi_course_screen.dart'; // L'écran une fois la course acceptée

class AttenteChauffeurScreen extends StatefulWidget {
  final int courseId;
  const AttenteChauffeurScreen({super.key, required this.courseId});

  @override
  State<AttenteChauffeurScreen> createState() => _AttenteChauffeurScreenState();
}

class _AttenteChauffeurScreenState extends State<AttenteChauffeurScreen> {
  Course? _course;
  bool _chargement = true;
  Timer? _minuterie;

  @override
  void initState() {
    super.initState();
    _charger();
    _minuterie = Timer.periodic(const Duration(seconds: 5), (_) => _charger());
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      // Utilise le singleton `api` (pattern correct) plutôt que const ApiClient()
      final reponse = await api.get('/courses/${widget.courseId}');
      if (!mounted) return;
      setState(() {
        _course = Course.depuisJson(
            (reponse['course'] ?? reponse['data']) as Map<String, dynamic>);
        _chargement = false;
      });
    } catch (_) {}
  }


  Future<void> _accepterPrix() async {
    try {
      await const CourseRepository().accepterPrix(widget.courseId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SuiviCourseScreen(courseId: widget.courseId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final enNegociation = _course?.statut == 'negociation';

    return Scaffold(
      appBar: AppBar(title: const Text('Recherche d\'un chauffeur')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!enNegociation) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('Nous cherchons un chauffeur pour vous...', textAlign: TextAlign.center),
              ] else ...[
                const Icon(Icons.local_taxi, size: 80, color: MabokoCouleurs.secondaire),
                const SizedBox(height: 24),
                const Text('Un chauffeur a répondu !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Il propose un tarif de ${_course?.prixChauffeur?.toStringAsFixed(0)} FCFA pour votre course.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                           // Annuler la course
                        },
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _accepterPrix,
                        style: FilledButton.styleFrom(backgroundColor: MabokoCouleurs.succes),
                        child: const Text('Accepter le prix'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}