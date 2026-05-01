import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AppAuthProvider with ChangeNotifier {
  AppAuthProvider(this._authService) {
    _subscription = _authService.authStateChanges().listen((user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _runAuthAction(
      () => _authService.signInWithEmail(email: email, password: password),
    );
  }

  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
  }) {
    return _runAuthAction(
      () => _authService.createAccount(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> signInWithGoogle() {
    return _runAuthAction(_authService.signInWithGoogle);
  }

  Future<void> signOut() async {
    _setBusy();
    try {
      await _authService.signOut();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _friendlyMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<Object?> Function() action) async {
    _setBusy();
    try {
      await action();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _friendlyMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setBusy() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'weak-password':
          return 'Use a stronger password.';
        case 'popup-closed-by-user':
        case 'canceled-popup-request':
          return 'Google sign-in was cancelled.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }

    return error.toString().replaceFirst('Bad state: ', '');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
