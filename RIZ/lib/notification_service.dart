import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════════
// NotificationService — Handles push notifications using FCM and local notifications

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  Future<void> _saveNotificationState(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<bool> requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      await _saveNotificationState(granted);
      if (granted) await _initializeNotifications();
      return granted;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  Future<void> _initializeNotifications() async {
    if (_isInitialized) return;
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $_fcmToken');

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed');
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundTap);

      _isInitialized = true;
      debugPrint('✅ Notifications initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📩 Foreground message: ${message.messageId}');
    await _showLocalNotification(
      title: message.notification?.title ?? 'RIZ Hub',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  void _handleBackgroundTap(RemoteMessage message) {
    debugPrint('📬 Notification opened app: ${message.messageId}');
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    // Auto-initialize if needed
    if (!_isInitialized) {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      _isInitialized = true;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'riz_channel',
      'RIZ Notifications',
      channelDescription: 'Notifications for RIZ Learning Hub',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    await _localNotifications.show(
      id ?? DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  /// ✅ NEW: Show a test notification immediately — call this from the app to verify
  Future<void> showTestNotification() async {
    // Make sure local notifications are initialized
    if (!_isInitialized) {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      _isInitialized = true;
    }

    await _showLocalNotification(
      title: '🎯 RIZ Hub — Notification Test',
      body: 'Notifications are working! You\'re all set. 🚀',
      payload: 'test',
      id: 999,
    );
    debugPrint('✅ Test notification sent');
  }

  Future<void> disableNotifications() async {
    await _saveNotificationState(false);
    debugPrint('🔕 Notifications disabled');
  }

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
}
