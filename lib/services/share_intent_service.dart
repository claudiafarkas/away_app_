import 'package:flutter/services.dart';

class ShareIntentService {
  ShareIntentService._();

  static final ShareIntentService instance = ShareIntentService._();

  static const MethodChannel _channel = MethodChannel('away/share_intent');

  String? _pendingSharedUrl;

  Future<void> refreshFromNative() async {
    try {
      final result = await _channel.invokeMethod<String>('getInitialSharedUrl');
      final trimmed = result?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        _pendingSharedUrl = trimmed;
      }
    } catch (_) {
      // Keep app flow intact if platform channel is unavailable.
    }
  }

  String? consumeSharedUrl() {
    final url = _pendingSharedUrl;
    _pendingSharedUrl = null;
    return url;
  }
}
