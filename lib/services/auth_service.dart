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
    try {
      print("🚀 Starting Google Sign In...");
      print(
        "📱 iOS Client ID: ${dotenv.env['IOS_CLIENT_ID']?.substring(0, 10)}...",
      );

      // Try sign in
      final googleUser = await _googleSignIn.signIn().catchError((error) {
        print("❌ GoogleSignIn.signIn() error: $error");
        throw error;
      });

      if (googleUser == null) {
        print("⚠️ User cancelled sign in");
        return null;
      }

      // Get auth details
      final googleAuth = await googleUser.authentication.catchError((error) {
        print("❌ Authentication error: $error");
        throw error;
      });

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      print("⚙️ Signing in to Firebase...");
      final userCredential = await _auth.signInWithCredential(credential);
      print("✅ Firebase sign in successful: ${userCredential.user?.uid}");

      // Save user data
      if (userCredential.user != null) {
        await saveUserToFirestore(userCredential.user!);
      }

      return userCredential;
    } catch (e, stack) {
      print("❌ Google Sign In failed: $e");
      print("Stack trace: $stack");
      throw e; // Rethrow to let UI handle it
    }
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
