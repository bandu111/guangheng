import 'dart:async';
import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/backend_models.dart';

typedef NotificationInteractionHandler = Future<void> Function(int? eventId);

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();
  static const _seenKey = 'local_notification_seen_ids_v1';
  static const _channelId = 'guangheng_energy_alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  NotificationInteractionHandler? _interactionHandler;
  int? _pendingEventId;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('notification_icon'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _dispatchPayload(response.payload);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _capturePayload(launch?.notificationResponse?.payload);
    }
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (!_initialized || kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (_) {
      // The in-app notification center remains usable if system permission is
      // unavailable or the current launcher doesn't support notifications.
    }
  }

  void setInteractionHandler(NotificationInteractionHandler handler) {
    _interactionHandler = handler;
    final pending = _pendingEventId;
    _pendingEventId = null;
    if (pending != null) unawaited(handler(pending));
  }

  void clearInteractionHandler(NotificationInteractionHandler handler) {
    if (identical(_interactionHandler, handler)) _interactionHandler = null;
  }

  Future<void> sync(
    List<NotificationEventModel> events,
    int unreadCount,
  ) async {
    if (!_initialized || kIsWeb) return;
    await _updateBadge(unreadCount);
    final preferences = await SharedPreferences.getInstance();
    final seen = preferences.getStringList(_seenKey)?.toSet() ?? <String>{};
    for (final event in events.where(
      (event) => event.status.toUpperCase() != 'UNREAD',
    )) {
      await _plugin.cancel(id: event.id);
    }
    final unread =
        events.where((event) => event.status.toUpperCase() == 'UNREAD').toList()
          ..sort(
            (a, b) => (a.createdAt ?? DateTime(1970)).compareTo(
              b.createdAt ?? DateTime(1970),
            ),
          );
    for (final event in unread) {
      final key = '${event.id}';
      if (seen.contains(key)) continue;
      await _show(event, unreadCount);
      seen.add(key);
    }
    final retained = seen.toList();
    if (retained.length > 200) {
      retained.removeRange(0, retained.length - 200);
    }
    await preferences.setStringList(_seenKey, retained);
  }

  Future<void> cancelEvent(int eventId) async {
    if (!_initialized || kIsWeb) return;
    await _plugin.cancel(id: eventId);
  }

  Future<void> _show(NotificationEventModel event, int unreadCount) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        '家庭能源提醒',
        channelDescription: '待确认方案、设备状态和能源异常提醒',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        number: unreadCount,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: unreadCount,
      ),
    );
    await _plugin.show(
      id: event.id,
      title: event.title,
      body: event.message,
      notificationDetails: details,
      payload: 'notification:${event.id}',
    );
  }

  Future<void> _updateBadge(int count) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await AppBadgePlus.updateBadge(count.clamp(0, 999));
    } catch (_) {
      // Some Android launchers don't expose a numeric badge API. The active
      // notification still provides the standard notification dot/count.
    }
  }

  void _dispatchPayload(String? payload) {
    final eventId = _eventId(payload);
    final handler = _interactionHandler;
    if (handler == null) {
      _pendingEventId = eventId;
    } else {
      unawaited(handler(eventId));
    }
  }

  void _capturePayload(String? payload) {
    _pendingEventId = _eventId(payload);
  }

  int? _eventId(String? payload) {
    if (payload == null || !payload.startsWith('notification:')) return null;
    return int.tryParse(payload.substring('notification:'.length));
  }
}
