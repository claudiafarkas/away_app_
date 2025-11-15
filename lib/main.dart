import 'package:flutter/material.dart';
import 'package:away/views/welcome_load/welcome_load_screen.dart';
import 'package:away/views/imported/imported_screen.dart';
import 'package:away/views/map/map_screen.dart';
import 'package:away/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:away/views/import/manual_import_screen.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }

  // Initialize Firebase Remote Config
  final remoteConfig = FirebaseRemoteConfig.instance;

  try {
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: Duration(seconds: 10),
        minimumFetchInterval: Duration(hours: 1),
      ),
    );

    await remoteConfig.fetchAndActivate();
    print("✅ Remote Config activated");
    print("🔑 IOS_CLIENT_ID: ${remoteConfig.getString('IOS_CLIENT_ID')}");
  } catch (e) {
    print("❌ Remote Config failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Away App',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF062D40)),
        scaffoldBackgroundColor: const Color.fromARGB(255, 6, 29, 41),
      ),
      home: const WelcomeLoad(),
      routes: {
        '/imported_screen': (context) => MyImportsScreen(),
        '/map': (context) => const MapScreen(),
        '/manual_import_screen': (context) => const ManualImportScreen(),
      },
    );
  }
}
