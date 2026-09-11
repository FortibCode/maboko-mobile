import 'package:flutter/material.dart';

/// Ouvre une photo en plein écran, agrandissable au doigt.
///
/// Les réalisations d'un portfolio n'étaient visibles qu'en vignette de 118
/// pixels sur la fiche artisan, et rien ne réagissait au toucher : le client
/// devait juger un savoir-faire sur un timbre-poste.
class VisionneusePhoto extends StatelessWidget {
  const VisionneusePhoto({super.key, required this.urls, this.depart = 0, this.legende});

  final List<String> urls;
  final int depart;
  final String? legende;

  static Future<void> ouvrir(
    BuildContext context, {
    required List<String> urls,
    int depart = 0,
    String? legende,
  }) {
    if (urls.isEmpty) return Future.value();

    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VisionneusePhoto(urls: urls, depart: depart, legende: legende),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controleur = PageController(initialPage: depart);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          urls.length > 1 ? '${depart + 1} / ${urls.length}' : 'Réalisation',
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controleur,
              itemCount: urls.length,
              itemBuilder: (contexte, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    urls[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (contexte, enfant, progression) => progression == null
                        ? enfant
                        : const Center(
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                    errorBuilder: (contexte, erreur, trace) => const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (legende != null && legende!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Text(
                legende!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}
