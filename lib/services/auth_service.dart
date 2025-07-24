// lib/services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // at the top if not already
// import 'package:flutter_signin_button/flutter_signin_button.dart';

class AuthService {
  AuthService._(); // private constructor
  static final instance = AuthService._();

  final _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['YOUR_IOS_CLIENT_ID'] ?? '',
    scopes: ['email'],
  );

  final _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Save user to Firestore
    final user = userCredential.user;
    if (user != null) {
      await saveUserToFirestore(user);
    }

    return userCredential;
  }

  Future<void> saveUserToFirestore(User user) async {
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userDoc.set({
      'name': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Optional: sign out from both providers.
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
