import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService();

  bool _googleInitialized = false;

  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final displayName = name.trim();
    if (displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();
    }

    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      return _firebaseAuth.signInWithPopup(provider);
    }

    await GoogleSignIn.instance.initialize(
      serverClientId:
          '571549908150-3j18h1fgrt6ce09ea5bpdov2mas6al00.apps.googleusercontent.com',
    );
    final GoogleSignInAccount? googleUser =
        await GoogleSignIn.instance.authenticate();

    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'canceled-popup-request',
        message: 'Sign-in was cancelled by the user.',
      );
    }

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    
    // In v7.x, accessToken must be requested via authorizationClient
    final authorization = await googleUser.authorizationClient.authorizeScopes([
      'email',
      'profile',
    ]);

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: authorization.accessToken,
      idToken: googleAuth.idToken,
    );

    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait<void>([
      _firebaseAuth.signOut(),
      GoogleSignIn.instance.signOut().catchError((_) => null),
    ]);
  }
}
