import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles an FCM payload received while the app is backgrounded or
/// terminated. Must be a top-level function (not a class method) so the
/// platform can invoke it in a separate isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[NotificationService] Background message: ${message.messageId}',
  );
}

/// Content for the local notification to show for a foreground FCM
/// message, or null if there's nothing displayable in it. A pure decision
/// separate from the actual plugin call so it can be unit tested without
/// a real notifications platform channel.
({int id, String title, String body})? notificationContentFor(
  RemoteMessage message,
) {
  final notification = message.notification;
  if (notification == null) return null;
  final title = notification.title;
  final body = notification.body;
  if (title == null && body == null) return null;
  return (
    id: message.messageId?.hashCode ?? message.hashCode,
    title: title ?? 'Nodus Protocol',
    body: body ?? '',
  );
}

/// Registers the device for push notifications and displays foreground
/// messages locally. This repo doesn't ship a real Firebase project
/// config yet (no google-services.json / GoogleService-Info.plist), so
/// [initialize] catches and swallows any setup failure instead of
/// crashing startup -- the same posture firebase_analytics and
/// firebase_crashlytics are already in in this codebase.
class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _injectedMessaging = messaging,
        _injectedLocalNotifications = localNotifications;

  static const _channelId = 'transaction_status';
  static const _channelName = 'Transaction Status Updates';

  final FirebaseMessaging? _injectedMessaging;
  final FlutterLocalNotificationsPlugin? _injectedLocalNotifications;

  // Deliberately `late final` rather than resolved in the initializer
  // list: FirebaseMessaging.instance throws if Firebase.initializeApp()
  // hasn't completed yet, so it must not be touched until initialize()
  // reaches this point -- never at construction time.
  late final FirebaseMessaging _messaging =
      _injectedMessaging ?? FirebaseMessaging.instance;
  late final FlutterLocalNotificationsPlugin _localNotifications =
      _injectedLocalNotifications ?? FlutterLocalNotificationsPlugin();

  String? _token;

  /// The device's FCM registration token, once [initialize] has completed
  /// successfully. Null before that, and null if Firebase isn't
  /// configured for this build.
  String? get token => _token;

  /// Returns true once permission was requested and the token fetched;
  /// false (without throwing) if Firebase isn't configured for this
  /// build yet.
  Future<bool> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[NotificationService] Firebase not configured: $e');
      return false;
    }

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _messaging.requestPermission();
    _token = await _messaging.getToken();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    return true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final content = notificationContentFor(message);
    if (content == null) return;
    await _localNotifications.show(
      id: content.id,
      title: content.title,
      body: content.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
