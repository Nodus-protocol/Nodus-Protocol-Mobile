import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodus_protocol/services/notification_service.dart';

void main() {
  group('notificationContentFor', () {
    test('returns null when the message carries no notification', () {
      final message = RemoteMessage(data: const {'status': 'confirmed'});
      expect(notificationContentFor(message), isNull);
    });

    test('returns null when title and body are both absent', () {
      final message = RemoteMessage(notification: RemoteNotification());
      expect(notificationContentFor(message), isNull);
    });

    test('passes through a title and body', () {
      final message = RemoteMessage(
        messageId: 'msg-1',
        notification: RemoteNotification(
          title: 'Swap confirmed',
          body: 'Your swap of 100 XLM has settled.',
        ),
      );

      final content = notificationContentFor(message);

      expect(content, isNotNull);
      expect(content!.title, 'Swap confirmed');
      expect(content.body, 'Your swap of 100 XLM has settled.');
    });

    test('falls back to a default title when only a body is present', () {
      final message = RemoteMessage(
        notification: RemoteNotification(body: 'Transaction failed.'),
      );

      final content = notificationContentFor(message);

      expect(content, isNotNull);
      expect(content!.title, 'Nodus Protocol');
      expect(content.body, 'Transaction failed.');
    });

    test('falls back to an empty body when only a title is present', () {
      final message = RemoteMessage(
        notification: RemoteNotification(title: 'Heads up'),
      );

      final content = notificationContentFor(message);

      expect(content, isNotNull);
      expect(content!.title, 'Heads up');
      expect(content.body, '');
    });

    test('derives the notification id from messageId when present', () {
      final message = RemoteMessage(
        messageId: 'abc-123',
        notification: RemoteNotification(title: 'Hi'),
      );

      expect(notificationContentFor(message)!.id, 'abc-123'.hashCode);
    });
  });
}
