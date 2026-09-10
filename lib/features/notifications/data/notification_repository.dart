import '../../../core/network/api.dart';

/// Notification reçue par l'utilisateur.
class NotificationMaboko {
  const NotificationMaboko({
    required this.id,
    required this.titre,
    required this.corps,
    required this.type,
    required this.lue,
    this.recueLe,
  });

  final int id;
  final String titre;
  final String corps;
  final String type;
  final bool lue;
  final DateTime? recueLe;

  NotificationMaboko marquerLue() => NotificationMaboko(
        id: id,
        titre: titre,
        corps: corps,
        type: type,
        lue: true,
        recueLe: recueLe,
      );

  factory NotificationMaboko.depuisJson(Map<String, dynamic> json) => NotificationMaboko(
        id: json['id'] as int,
        titre: json['titre'] as String? ?? '',
        corps: json['corps'] as String? ?? '',
        type: json['type'] as String? ?? 'info',
        lue: json['lue'] as bool? ?? false,
        recueLe: DateTime.tryParse(json['recueLe'] as String? ?? ''),
      );
}

/// Liste des notifications et compteur de non-lues.
typedef ListeNotifications = ({List<NotificationMaboko> notifications, int nonLues});

class NotificationRepository {
  const NotificationRepository();

  Future<ListeNotifications> lister() async {
    final reponse = await api.get('/notifications') as Map<String, dynamic>;

    return (
      notifications: ((reponse['data'] as List?) ?? [])
          .map((n) => NotificationMaboko.depuisJson(n as Map<String, dynamic>))
          .toList(),
      nonLues: reponse['nonLues'] as int? ?? 0,
    );
  }

  Future<void> marquerLue(int id) => api.post('/notifications/$id/lu');

  Future<void> toutMarquerLu() => api.post('/notifications/lu');
}
