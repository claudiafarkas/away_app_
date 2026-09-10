import 'package:flutter/material.dart';
import 'package:away/services/import_service.dart';
import 'package:away/services/share_intent_service.dart';
import 'package:away/widgets/bottom_nav_scaffold.dart';

Future<void> enterSignedInApp(BuildContext context) async {
  await ImportService.instance.loadFromFirestore();
  if (!context.mounted) return;
  final sharedUrl = ShareIntentService.instance.consumeSharedUrl();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder:
          (_) => BottomNavScaffold(
            initialIndex: (sharedUrl ?? '').isNotEmpty ? 1 : 0,
            initialImportUrl: sharedUrl,
          ),
    ),
  );
}
