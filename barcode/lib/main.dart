import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/bill_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';
import 'screens/notifications_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/privacy_security_screen.dart';
import 'providers/security_provider.dart';
import 'providers/notification_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app resumes, check if security is required and reset session auth
      final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
      if (securityProvider.requireSecurityOnEntry) {
        securityProvider.resetAuthentication();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider(AuthService())),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Quick Bill',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF06B6D4),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF06B6D4),
                brightness: Brightness.dark,
                surface: const Color(0xFF1a1a2e),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const AuthGate(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/main': (context) => const MainScreen(),
              '/bill': (context) => const BillScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/help_support': (context) => const HelpSupportScreen(),
              '/privacy_security': (context) => const PrivacySecurityScreen(),
            },
            builder: (context, child) {
              return Stack(
                children: [
                  child!,
                  const NotificationOverlay(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppAuthProvider, SecurityProvider>(
      builder: (context, authProvider, securityProvider, child) {
        if (authProvider.isLoading && authProvider.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.user == null) {
          return const LoginScreen();
        }

        // Check if security lock is enabled and user is not yet authenticated for this session
        if (securityProvider.requireSecurityOnEntry && !securityProvider.isAuthenticated) {
          return const SecurityLockScreen();
        }

        return const MainScreen();
      },
    );
  }
}

class SecurityLockScreen extends StatefulWidget {
  const SecurityLockScreen({super.key});

  @override
  State<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends State<SecurityLockScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isBiometricAuthenticated = false;
  bool _isPinAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBiometricAuth();
    });
  }

  Future<void> _startBiometricAuth() async {
    final security = context.read<SecurityProvider>();
    if (!security.isBiometricEnabled) return;
    
    final success = await security.authenticateBiometrics();
    if (success) {
      setState(() => _isBiometricAuthenticated = true);
      _unlockApp();
    }
  }

  void _unlockApp() {
    context.read<SecurityProvider>().setAuthenticated(true);
    context.read<NotificationProvider>().showNotification(
          title: 'Welcome Back',
          message: 'Authentication successful',
          icon: Icons.verified_user,
          color: Colors.green,
        );
  }

  void _onPinChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyPin();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyPin() {
    final pin = _controllers.map((e) => e.text).join();
    if (context.read<SecurityProvider>().verifyPin(pin)) {
      setState(() => _isPinAuthenticated = true);
      _unlockApp();
    } else {
      // Clear PIN and show error
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final securityProvider = context.watch<SecurityProvider>();

    return Scaffold(
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isBiometricAuthenticated && _isPinAuthenticated
                        ? Icons.lock_open_outlined
                        : Icons.lock_person_outlined,
                    size: 64,
                    color: const Color(0xFF06B6D4),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Quick Bill Secure Entry',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isBiometricAuthenticated || _isPinAuthenticated
                      ? 'Authentication successful!'
                      : 'Please authenticate with Fingerprint or PIN',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),
                
                // PIN Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) => _onPinChanged(index, value),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        obscureText: true,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
                          ),
                          fillColor: isDark ? const Color(0xFF1f2937) : Colors.white,
                          filled: true,
                        ),
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 48),
                
                // Fingerprint Button
                if (securityProvider.isBiometricEnabled)
                  InkWell(
                    onTap: _startBiometricAuth,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isBiometricAuthenticated ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isBiometricAuthenticated ? Colors.green : const Color(0xFF06B6D4),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _isBiometricAuthenticated ? Icons.check : Icons.fingerprint,
                        size: 48,
                        color: _isBiometricAuthenticated ? Colors.green : const Color(0xFF06B6D4),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                if (securityProvider.isBiometricEnabled)
                  Text(
                    _isBiometricAuthenticated ? 'Fingerprint Verified' : 'Scan Fingerprint',
                    style: TextStyle(
                      color: _isBiometricAuthenticated ? Colors.green : const Color(0xFF06B6D4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}

class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final notification = provider.currentNotification;
        if (notification == null) return const SizedBox.shrink();

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * -20),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1f2937)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: notification.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notification.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(notification.icon, color: notification.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            notification.message,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: provider.hideNotification,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
