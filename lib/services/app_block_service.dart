import 'package:flutter/services.dart';

class AppBlockService {
  static const MethodChannel _channel = MethodChannel('com.muslimlauncher/block');
  
  static final AppBlockService _instance = AppBlockService._internal();
  factory AppBlockService() => _instance;
  AppBlockService._internal();

  Function(String)? _onAppBlocked;

  void init({required Function(String) onAppBlocked}) {
    _onAppBlocked = onAppBlocked;
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onAppBlocked':
        final String? packageName = call.arguments['packageName'];
        if (packageName != null && _onAppBlocked != null) {
          _onAppBlocked!(packageName);
        }
        break;
      default:
        break;
    }
  }

  Future<void> setBlockedApps(List<String> packages) async {
    try {
      await _channel.invokeMethod('setBlockedApps', {'packages': packages});
    } on PlatformException catch (e) {
      print("Failed to sync blocked apps: ${e.message}");
    }
  }

  Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod('isAccessibilityServiceEnabled');
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print("Failed to open settings: ${e.message}");
    }
  }

  Future<void> allowAppTemporarily(String packageName, {int durationMinutes = 60}) async {
    try {
      await _channel.invokeMethod('allowAppTemporarily', {
        'packageName': packageName,
        'durationMillis': durationMinutes * 60 * 1000,
      });
    } on PlatformException catch (e) {
      print("Failed to allow app: ${e.message}");
    }
  }
}
