import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service de notifications locales (§5.3.2).
///
/// Utilisé pour prévenir le chauffeur quand une nouvelle course est proposée,
/// et le client quand son chauffeur accepte. Les notifications sont locales :
/// elles ne nécessitent ni Firebase, ni modification du serveur.
///
/// Un canal Android unique regroupe toutes les notifications de course :
/// le chauffeur peut le couper d'un seul geste dans les réglages système.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialise = false;

  /// Canal Android : importance haute pour sonner même en mode silencieux.
  static const _canalCourses = AndroidNotificationChannel(
    'maboko_courses',
    'Courses Allô Chauffeur',
    description: 'Nouvelles courses proposées et mises à jour de statut.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// À appeler une fois au démarrage de l'application (dans `main`).
  static Future<void> initialiser() async {
    if (_initialise) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const reglages = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(reglages);

    // Crée le canal Android et demande la permission (Android 13+).
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_canalCourses);
      await androidPlugin.requestNotificationsPermission();
    }

    _initialise = true;
  }

  /// Affiche une notification de course.
  ///
  /// [id] doit être unique par course : une nouvelle notification remplace
  /// l'ancienne si on réutilise le même id.
  static Future<void> notifierCourse({
    required int id,
    required String titre,
    required String corps,
  }) async {
    if (!_initialise) await initialiser();

    const androidDetails = AndroidNotificationDetails(
      'maboko_courses',
      'Courses Allô Chauffeur',
      channelDescription: 'Nouvelles courses proposées et mises à jour de statut.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, titre, corps, details);
  }
}