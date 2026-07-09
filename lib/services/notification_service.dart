import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
