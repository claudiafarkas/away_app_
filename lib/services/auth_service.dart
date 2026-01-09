// lib/services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // at the top if not already
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
// import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  AuthService._() {
    // private constructor
    _initializeRemoteConfig();
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final instance = AuthService._();

  // final _googleSignIn = GoogleSignIn(
  //   clientId: FirebaseRemoteConfig.instance.getString('IOS_CLIENT_ID'),
  //   scopes: ['email'],
  // );
  final _googleSignIn = GoogleSignIn(scopes: ['email']);

  final _auth = FirebaseAuth.instance;
  final _secureStorage = const FlutterSecureStorage();

  // Commented out bc it kep causing issues
  // Future<UserCredential?> signInWithGoogle() async {
  //   try {
  //     print("🚀 Starting Google Sign In...");

  //     // Try sign in
  //     final googleUser = await _googleSignIn.signIn().catchError((error) {
  //       print("❌ GoogleSignIn.signIn() error: $error");
  //       throw error;
  //     });

  //     if (googleUser == null) {
  //       print("⚠️ User cancelled sign in");
  //       return null;
  //     }

  //     // Get auth details
  //     final googleAuth = await googleUser.authentication.catchError((error) {
  //       print("❌ Authentication error: $error");
  //       throw error;
  //     });

  //     // Create credential
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     // Sign in to Firebase
  //     print("⚙️ Signing in to Firebase...");
  //     final userCredential = await _auth.signInWithCredential(credential);
  //     print("✅ Firebase sign in successful: ${userCredential.user?.uid}");

  //     // Save user data
  //     if (userCredential.user != null) {
  //       await saveUserToFirestore(userCredential.user!);
  //     }

  //     return userCredential;
  //   } catch (e, stack) {
  //     print("❌ Google Sign In failed: $e");
  //     print("Stack trace: $stack");
  //     throw e; // Rethrow to let UI handle it
  //   }
  // }

  Future<UserCredential?> signInWithApple() async {
    try {
      print("🍎 Starting Sign in with Apple...");

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (appleCredential.identityToken == null) {
        throw Exception("Missing Apple identity token");
      }

      // Persist token for potential future silent sign-in
      await _secureStorage.write(
        key: 'apple_identity_token',
        value: appleCredential.identityToken,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      print("⚙️ Signing in to Firebase with Apple credential...");
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      print("✅ Apple sign-in successful: ${userCredential.user?.uid}");

      if (userCredential.user != null) {
        await saveUserToFirestore(userCredential.user!);
      }

      return userCredential;
    } catch (e, stack) {
      print("❌ Apple Sign In failed: $e");
      print("Stack trace: $stack");
      rethrow;
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

  Future<void> _initializeRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: Duration(seconds: 10),
          minimumFetchInterval: Duration(hours: 1),
        ),
      );

      await remoteConfig.fetchAndActivate();

      final iosClientId = remoteConfig.getString('IOS_CLIENT_ID');
      print(
        "📡 RemoteConfig IOS_CLIENT_ID: ${iosClientId.substring(0, 10)}...",
      );
    } catch (e) {
      print("❌ Failed to initialize Remote Config: $e");
    }
  }

  /// Optional: sign out from both providers.
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
