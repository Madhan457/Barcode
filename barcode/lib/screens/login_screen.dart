import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _signInWithEmail() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await context.read<AppAuthProvider>().signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    await context.read<AppAuthProvider>().signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final isBusy = authProvider.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2563eb),
              Color(0xFF9333ea),
              Color(0xFF2563eb),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF60a5fa), Color(0xFFa855f7)],
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shopping_cart_checkout,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(color: Color(0xFFbfdbfe), fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [

                          if (authProvider.errorMessage != null) ...[
                            _buildMessage(
                              authProvider.errorMessage!,
                              Icons.error_outline,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Semantics(
                            label: 'Email Input',
                            child: TextFormField(
                              restorationId: 'login_email_field',
                              controller: _emailController,
                              enabled: !isBusy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty || !email.contains('@')) {
                                  return 'Enter a valid email.';
                                }
                                return null;
                              },
                              decoration: _inputDecoration(
                                hintText: 'Email',
                                icon: Icons.mail_outline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            label: 'Password Input',
                            child: TextFormField(
                              restorationId: 'login_password_field',
                              controller: _passwordController,
                              enabled: !isBusy,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signInWithEmail(),
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if ((value ?? '').length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                              decoration: _inputDecoration(
                                hintText: 'Password',
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFFbfdbfe),
                                  ),
                                  onPressed: isBusy
                                      ? null
                                      : () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isBusy ? null : _signInWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3b82f6),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isBusy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or',
                                  style: TextStyle(color: Color(0xFFbfdbfe)),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: isBusy ? null : _signInWithGoogle,
                              icon: const Icon(Icons.g_mobiledata, size: 28),
                              label: const Text('Continue with Google'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Color(0xFFbfdbfe)),
                      ),
                      TextButton(
                        onPressed: isBusy
                            ? null
                            : () {
                                authProvider.clearError();
                                Navigator.pushNamed(context, '/signup');
                              },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: Color(0xFF93c5fd),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFFbfdbfe)),
      suffixIcon: suffixIcon,
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFbfdbfe)),
      errorStyle: const TextStyle(color: Color(0xFFfecaca)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF60a5fa), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFfecaca), width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFfecaca), width: 2),
      ),
    );
  }

  Widget _buildMessage(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFbfdbfe), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
