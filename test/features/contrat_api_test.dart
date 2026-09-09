import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maboko_mobile/features/abonnement/models/plan.dart';
import 'package:maboko_mobile/features/artisans/models/artisan.dart';
import 'package:maboko_mobile/features/demandes/models/demande.dart';
import 'package:maboko_mobile/features/fil/models/publication.dart';
import 'package:maboko_mobile/features/messagerie/models/conversation.dart';
import 'package:maboko_mobile/features/metiers/models/metier.dart';
import 'package:maboko_mobile/features/tableau_bord/models/tableau_bord.dart';

/// Tests de contrat entre l'API Laravel et les modèles Dart.
///
/// Les fichiers de `test/fixtures` sont de vraies réponses capturées sur
/// l'API. Si un champ est renommé côté serveur, ces tests échouent — au lieu
/// que l'application affiche silencieusement « Inconnu », comme c'était le cas
/// pour le fil d'actualité avant la reprise.
void main() {
  Map<String, dynamic> lire(String nom) {
    final fichier = File('test/fixtures/$nom.json');
    expect(fichier.existsSync(), isTrue, reason: 'Fixture manquante : $nom.json');

    return jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
  }

  group('Référentiel des métiers', () {
    test('la réponse se convertit en liste de métiers', () {
      final donnees = lire('metiers')['data'] as List;
      final metiers = donnees.map((m) => Metier.depuisJson(m as Map<String, dynamic>)).toList();

      expect(metiers.length, greaterThanOrEqualTo(20));
      expect(metiers.map((m) => m.slug), contains('menuisier'));

      final menuisier = metiers.firstWhere((m) => m.slug == 'menuisier');
      expect(menuisier.nom, 'Menuisier');
      expect(menuisier.nbArtisans, greaterThan(0));
    });
  });

  group('Recherche d’artisans', () {
    test('les résultats géolocalisés portent une distance', () {
      final donnees = lire('artisans_recherche')['data'] as List;
      final artisans = donnees.map((a) => Artisan.depuisJson(a as Map<String, dynamic>)).toList();

      expect(artisans, isNotEmpty);
      expect(artisans.first.distanceKm, isNotNull);
      expect(artisans.first.nomComplet, isNot('Artisan Maboko'));
    });
  });

  group('Fiche artisan', () {
    late Artisan artisan;

    setUp(() => artisan = Artisan.depuisJson(lire('artisan_fiche')['data'] as Map<String, dynamic>));

    test('le nom est lu depuis « nom », pas « name »', () {
      expect(artisan.nomComplet, 'Pascal Nkodia');
    });

    test('les métiers et les badges sont présents', () {
      expect(artisan.metiers, containsAll(['Menuisier', 'Ébéniste']));
      expect(artisan.badges.map((b) => b.slug), contains('profil-verifie'));
    });

    test('la note et les avis remontent après notation', () {
      expect(artisan.noteMoyenne, 5.0);
      expect(artisan.nbAvis, 1);
      expect(artisan.nbMissionsTerminees, 1);
      expect(artisan.avis.first.commentaire, isNotEmpty);
    });

    test('le plan d’abonnement est exposé pour la mise en avant', () {
      expect(artisan.plan, 'pro');
      expect(artisan.estMisEnAvant, isTrue);
    });
  });

  group('Fil d’actualité', () {
    test('une publication porte son auteur, ses médias et ses compteurs', () {
      final donnees = lire('fil')['data'] as List;
      final publications = donnees
          .map((p) => Publication.depuisJson(p as Map<String, dynamic>))
          .toList();

      expect(publications, isNotEmpty);

      final premiere = publications.first;
      expect(premiere.auteur.nomComplet, 'Pascal Nkodia');
      expect(premiere.auteur.metier, 'Menuisier');
      expect(premiere.medias.length, 2);
      expect(premiere.likesCount, 1);
      expect(premiere.commentsCount, 1);
      // Le like est propre au lecteur : le serveur le calcule pour lui.
      expect(premiere.isLiked, isTrue);
    });

    test('les stories se convertissent', () {
      final donnees = lire('stories')['data'] as List;
      final stories = donnees
          .map((s) => StoryItem.depuisJson(s as Map<String, dynamic>))
          .toList();

      expect(stories.single.legende, 'Chantier du jour');
      expect(stories.single.auteur.nomComplet, 'Pascal Nkodia');
    });

    test('les commentaires portent le nom de leur auteur', () {
      final donnees = lire('commentaires')['data'] as List;
      final commentaires = donnees
          .map((c) => Commentaire.depuisJson(c as Map<String, dynamic>))
          .toList();

      expect(commentaires.single.auteurNom, 'Jean Makaya');
      expect(commentaires.single.contenu, 'Magnifique travail, bravo !');
    });
  });

  group('Abonnements', () {
    test('les quatre formules se convertissent', () {
      final donnees = lire('plans')['data'] as List;
      final plans = donnees.map((p) => Plan.depuisJson(p as Map<String, dynamic>)).toList();

      expect(plans.length, 4);
      expect(plans.map((p) => p.slug), ['gratuit', 'pro', 'premium', 'entreprise']);

      final gratuit = plans.first;
      expect(gratuit.estGratuit, isTrue);
      expect(gratuit.prixMensuel, 0);

      // Le multiplicateur de visibilité croît avec la formule (§4.5).
      final boosts = plans.map((p) => p.boostClassement).toList();
      expect(boosts, List<double>.from(boosts)..sort());
    });

    test('l’économie annuelle est calculée', () {
      final donnees = lire('plans')['data'] as List;
      final pro = donnees
          .map((p) => Plan.depuisJson(p as Map<String, dynamic>))
          .firstWhere((p) => p.slug == 'pro');

      expect(pro.economieAnnuelle, pro.prixMensuel * 12 - pro.prixAnnuel);
      expect(pro.economieAnnuelle, greaterThan(0));
    });

    test('la formule en cours porte sa date de fin', () {
      final abonnement = AbonnementActuel.depuisJson(lire('abonnement'));

      expect(abonnement.plan.slug, 'premium');
      expect(abonnement.finLe, isNotNull);
      expect(abonnement.renouvellementAuto, isTrue);
    });
  });

  group('Messagerie', () {
    test('la liste montre l’interlocuteur et les non-lus', () {
      final donnees = lire('conversations')['data'] as List;
      final conversations = donnees
          .map((c) => Conversation.depuisJson(c as Map<String, dynamic>))
          .toList();

      final fil = conversations.single;
      expect(fil.interlocuteur.nomComplet, 'Pascal Nkodia');
      expect(fil.estSupport, isFalse);
      // Une réponse reçue dans la même seconde que son propre envoi doit
      // bien compter comme non lue.
      expect(fil.nonLus, 1);
      expect(fil.dernierMessage, contains('jeudi matin'));
    });

    test('les messages distinguent l’expéditeur', () {
      final donnees = lire('messages')['data'] as List;
      final messages = donnees
          .map((m) => MessageChat.depuisJson(m as Map<String, dynamic>))
          .toList();

      expect(messages.length, 2);
      // L'API renvoie du plus récent au plus ancien.
      expect(messages.first.deMoi, isFalse);
      expect(messages.last.deMoi, isTrue);
    });
  });

  group('Tableau de bord', () {
    test('les compteurs du client remplacent les valeurs en dur', () {
      final bord = TableauBord.depuisJson(lire('bord_client'));

      expect(bord.estArtisan, isFalse);
      expect(bord.compteurs.total, 2);
      expect(bord.compteurs.enAttente, 1);
      expect(bord.compteurs.terminees, 1);
      expect(bord.favoris, 1);
      expect(bord.avisDeposes, 1);
      expect(bord.montantEngage, 190000);
    });

    test('l’artisan voit ses missions, ses revenus et son abonnement', () {
      final bord = TableauBord.depuisJson(lire('bord_artisan'));

      expect(bord.estArtisan, isTrue);
      expect(bord.ficheManquante, isFalse);
      expect(bord.compteurs.terminees, 1);
      expect(bord.revenusTotal, 190000);
      expect(bord.revenusMois, 190000);
      expect(bord.noteMoyenne, 5.0);
      expect(bord.plan, 'Pro');
      expect(bord.badges.map((b) => b.nom), contains('Profil vérifié'));
      // Seules les missions à traiter remontent sur le tableau de bord.
      expect(bord.dernieresDemandes.single.statut, 'en_attente');
    });
  });

  group('Demandes de devis', () {
    test('la liste du client se convertit', () {
      final donnees = lire('demandes_client')['data'] as List;
      final demandes = donnees.map((d) => Demande.depuisJson(d as Map<String, dynamic>)).toList();

      expect(demandes, isNotEmpty);
      expect(demandes.first.artisanNom, 'Pascal Nkodia');
    });

    test('le détail porte les montants et le statut final', () {
      final demande = Demande.depuisJson(lire('demande_detail')['data'] as Map<String, dynamic>);

      expect(demande.titre, 'Buffet en bois massif');
      expect(demande.statut, 'terminee');
      expect(demande.estTerminee, isTrue);
      expect(demande.estCloturee, isTrue);
      expect(demande.budgetEstime, 180000);
      expect(demande.montantPropose, 195000);
      expect(demande.montantFinal, 190000);
      expect(demande.metier, 'Menuisier');
    });
  });
}
