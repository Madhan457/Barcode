import 'package:flutter/material.dart';

class AppNotification {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  AppNotification({
    required this.title,
    required this.message,
    this.icon = Icons.notifications,
    this.color = const Color(0xFF06B6D4),
  });
}

class NotificationProvider with ChangeNotifier {
  AppNotification? _currentNotification;
  AppNotification? get currentNotification => _currentNotification;

  void showNotification({
    required String title,
    required String message,
    IconData icon = Icons.notifications,
    Color color = const Color(0xFF06B6D4),
  }) {
    _currentNotification = AppNotification(
      title: title,
      message: message,
      icon: icon,
      color: color,
    );
    notifyListeners();

    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentNotification?.title == title && _currentNotification?.message == message) {
        hideNotification();
      }
    });
  }

  void hideNotification() {
    _currentNotification = null;
    notifyListeners();
  }
}
