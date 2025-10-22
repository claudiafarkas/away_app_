// lib/services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // at the top if not already
import 'dart:io';
// import 'package:flutter_signin_button/flutter_signin_button.dart';

class AuthService {
  AuthService._() {
    // private constructor
    print(
      'ENV IOS_CLIENT_ID: ${dotenv.env['IOS_CLIENT_ID']?.substring(0, 10)}...',
    );
    print('ENV file location: ${Directory.current.path}/.env');
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final instance = AuthService._();

  final _googleSignIn = GoogleSignIn(
    clientId: dotenv.env['IOS_CLIENT_ID'] ?? '',
    scopes: ['email'],
  );

  final _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    print("⚙️ Signing in with credential...");
    // Sign in to Firebase with the Google [UserCredential]
    UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );

    print("✅ Signed in. UID: ${userCredential.user?.uid}");

    // Save user to Firestore
    final user = userCredential.user;

    if (user != null) {
      await saveUserToFirestore(user);
      print("✅ User saved to Firestore: ${user.uid}");
    }
    return userCredential;
  }

  Future<void> saveUserToFirestore(User user) async {
    print("📥 Entered saveUserToFirestore()");
    try {
      print("📤 Writing to /users/${user.uid}");
      print("🔐 Auth UID: ${FirebaseAuth.instance.currentUser?.uid}");

      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.set({
        'name': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Firestore write successful.");
    } catch (e) {
      print("❌ Firestore write failed: $e");
      // Re-throw so UI can catch and handle
      throw e;
    }
  }

  /// Optional: sign out from both providers.
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
