import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'product_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final ProductChecker _productChecker = ProductChecker();
  User? _user;

  // Inicialización de las notificaciones
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/noti_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Método para enviar una notificación
  Future<void> showNotification(int id, String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_notifications_channel',
      'Daily Notifications',
      channelDescription: 'Daily notifications for product warnings',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);
    await _flutterLocalNotificationsPlugin.show(
        id, title, body, notificationDetails);
  }

  // Método para verificar y notificar productos por vencer
  Future<void> checkAndNotifyExpiringProducts(String userId) async {
    bool hasExpiringProducts =
        await _productChecker.checkExpiringProducts(userId);
    if (hasExpiringProducts) {
      await showNotification(1, 'Tienes productos por vencer',
          'Revisa tus productos próximos a vencer.');
    }
  }

  // Método para verificar y notificar productos bajo stock
  Future<void> checkAndNotifyLowStock(String userId) async {
    bool hasLowStockProducts =
        await _productChecker.checkLowStockProducts(userId);
    if (hasLowStockProducts) {
      await showNotification(2, 'Tienes productos bajo stock',
          'Revisa tus productos con bajo stock.');
    }
  }

  // Método para programar la verificación diaria
  void scheduleDailyNotifications() {
    Timer.periodic(Duration(days: 1), (timer) async {
      await checkAndNotifyExpiringProducts(_user!.uid);
      await checkAndNotifyLowStock(_user!.uid);
    });
  }
}
