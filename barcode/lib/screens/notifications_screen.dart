import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _orderUpdates = true;
  bool _paymentAlerts = true;
  bool _securityWarnings = true;
  bool _promotionalOffers = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF111827), const Color(0xFF1f2937)]
                  : [const Color(0xFFf9fafb), const Color(0xFFdbeafe)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF111827), const Color(0xFF1f2937)]
                : [const Color(0xFFf9fafb), const Color(0xFFdbeafe)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Transactions'),
            _buildSwitchTile(
              title: 'Order Updates',
              subtitle: 'Get notified when a bill is generated or modified',
              value: _orderUpdates,
              icon: Icons.receipt_long,
              color: Colors.blue,
              onChanged: (val) => setState(() => _orderUpdates = val),
            ),
            _buildSwitchTile(
              title: 'Payment Alerts',
              subtitle: 'Notifications for successful UPI payments',
              value: _paymentAlerts,
              icon: Icons.payments_outlined,
              color: Colors.green,
              onChanged: (val) => setState(() => _paymentAlerts = val),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Security & Account'),
            _buildSwitchTile(
              title: 'Security Warnings',
              subtitle: 'Alerts for login attempts from new devices',
              value: _securityWarnings,
              icon: Icons.security,
              color: Colors.orange,
              onChanged: (val) => setState(() => _securityWarnings = val),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Marketing'),
            _buildSwitchTile(
              title: 'Promotional Offers',
              subtitle: 'Receive updates about new features and discounts',
              value: _promotionalOffers,
              icon: Icons.local_offer_outlined,
              color: Colors.purple,
              onChanged: (val) => setState(() => _promotionalOffers = val),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1f2937) : Colors.white,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : (title == 'Order Updates' || title == 'Security Warnings' || title == 'Promotional Offers'
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.zero),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF06B6D4),
        ),
      ),
    );
  }
}
