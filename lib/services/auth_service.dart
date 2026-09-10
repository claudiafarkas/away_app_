// lib/services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // at the top if not already
import 'package:firebase_remote_config/firebase_remote_config.dart';
// import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:away/services/import_service.dart';

class AuthService {
  AuthService._() {
    // private constructor
    _initializeRemoteConfig();
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final instance = AuthService._();

  // iOS client ID lives in Info.plist as GIDClientID (passing it here from
  // Remote Config at construct time is what used to break sign-in).
  // serverClientId is the Web OAuth client, needed for a Firebase ID token.
  final _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId:
        '975056194033-oloek9p28ju7h6bn6nvk5f915o70h8ri.apps.googleusercontent.com',
  );

  final _auth = FirebaseAuth.instance;
  final _secureStorage = const FlutterSecureStorage();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await saveUserToFirestore(userCredential.user!);
      }
      return userCredential;
    } catch (e, stack) {
      print("❌ Google Sign In failed: $e");
      print("Stack trace: $stack");
      rethrow;
    }
  }

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
    ImportService.instance.clearAll();
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
