import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/security_provider.dart';
import '../providers/notification_provider.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final securityProvider = Provider.of<SecurityProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
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
            _buildSectionHeader('Access Control'),
            _buildToggleItem(
              icon: Icons.security,
              title: 'Require Security on Entry',
              subtitle: 'Enable PIN or Fingerprint for app start',
              value: securityProvider.requireSecurityOnEntry,
              color: Colors.blue,
              onChanged: (val) {
                securityProvider.setRequireSecurity(val);
                notificationProvider.showNotification(
                  title: 'Security Updated',
                  message: 'Entry lock ${val ? 'enabled' : 'disabled'}',
                  icon: Icons.lock,
                  color: Colors.blue,
                );
              },
              isDark: isDark,
              isFirst: true,
              isLast: !securityProvider.requireSecurityOnEntry,
            ),
            
            if (securityProvider.requireSecurityOnEntry) ...[
              _buildActionItem(
                icon: Icons.pin,
                title: securityProvider.isPinSet ? 'Update PIN' : 'Set Security PIN',
                subtitle: securityProvider.isPinSet ? '4-digit PIN is active' : 'Set your secure PIN first',
                color: Colors.orange,
                onTap: () => _showPinEntryDialog(context, securityProvider, notificationProvider),
                isDark: isDark,
              ),
              _buildToggleItem(
                icon: Icons.fingerprint,
                title: 'Fingerprint Lock',
                subtitle: 'Use fingerprint for extra security',
                value: securityProvider.isBiometricEnabled,
                color: Colors.teal,
                onChanged: (val) {
                  if (!securityProvider.isPinSet) {
                    _showPinFirstDialog(context, securityProvider, notificationProvider);
                  } else {
                    securityProvider.setBiometricEnabled(val);
                    notificationProvider.showNotification(
                      title: 'Security Updated',
                      message: 'Fingerprint lock ${val ? 'enabled' : 'disabled'}',
                      icon: Icons.fingerprint,
                      color: Colors.teal,
                    );
                  }
                },
                isDark: isDark,
                isLast: true,
              ),
            ],
            
            const SizedBox(height: 24),
            _buildSectionHeader('Privacy Policy'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1f2937) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Collection',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick Bill collects information necessary to provide billing services, including your store name, product details, and transaction history. We do not sell your personal data to third parties.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Security Measures',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We use Firebase authentication and secure cloud storage to protect your data. All sensitive transaction information is encrypted and accessible only to authorized users.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'User Rights',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have the right to access, update, or request the deletion of your account data. For any privacy-related inquiries, contact innovexa.techno@gmail.com.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Your data is end-to-end encrypted',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinFirstDialog(BuildContext context, SecurityProvider security, NotificationProvider notifications) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN Setup Required'),
        content: const Text('Please set up your 4-digit security PIN first before enabling this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPinEntryDialog(context, security, notifications);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
            ),
            child: const Text('Set PIN Now'),
          ),
        ],
      ),
    );
  }

  void _showPinEntryDialog(BuildContext context, SecurityProvider security, NotificationProvider notifications) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinSetupDialog(
        onSave: (pin) {
          security.setPin(pin);
          notifications.showNotification(
            title: 'PIN Set Successfully',
            message: 'Security features are now unlocked',
            icon: Icons.check_circle,
            color: Colors.green,
          );
        },
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

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1f2937) : Colors.white,
        borderRadius: isFirst
            ? const BorderRadius.vertical(top: Radius.circular(16))
            : (isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
        ),
      ),
      child: ListTile(
        onTap: onTap,
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
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1f2937) : Colors.white,
        borderRadius: isFirst
            ? const BorderRadius.vertical(top: Radius.circular(16))
            : (isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero),
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

class PinSetupDialog extends StatefulWidget {
  final Function(String) onSave;

  const PinSetupDialog({super.key, required this.onSave});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  void _onPinChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Center(child: Text('Setup Security PIN')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter a 4-digit PIN for app access',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: 45,
                height: 45,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  onChanged: (value) => _onPinChanged(index, value),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  obscureText: true,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                    ),
                    fillColor: isDark ? const Color(0xFF111827) : Colors.grey.shade100,
                    filled: true,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isComplete
              ? () {
                  final pin = _controllers.map((e) => e.text).join();
                  widget.onSave(pin);
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06B6D4),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save PIN'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}
