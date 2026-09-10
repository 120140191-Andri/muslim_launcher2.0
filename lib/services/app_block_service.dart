import 'package:flutter/services.dart';

class AppBlockService {
  static const MethodChannel _channel = MethodChannel('com.muslimlauncher/block');
  
  static final AppBlockService _instance = AppBlockService._internal();
  factory AppBlockService() => _instance;
  AppBlockService._internal();

  Function(String)? _onAppBlocked;
  Function(String)? _onGhadhulBasharTriggered;
  Function(String)? _onProhibitedAppTriggered;

  void init({
    required Function(String) onAppBlocked,
    Function(String)? onGhadhulBasharTriggered,
    Function(String)? onProhibitedAppTriggered,
  }) {
    _onAppBlocked = onAppBlocked;
    _onGhadhulBasharTriggered = onGhadhulBasharTriggered;
    _onProhibitedAppTriggered = onProhibitedAppTriggered;
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
      case 'onGhadhulBasharTriggered':
        final String? packageName = call.arguments['packageName'];
        if (packageName != null && _onGhadhulBasharTriggered != null) {
          _onGhadhulBasharTriggered!(packageName);
        }
        break;
      case 'onProhibitedAppTriggered':
        final String? packageName = call.arguments['packageName'];
        if (packageName != null && _onProhibitedAppTriggered != null) {
          _onProhibitedAppTriggered!(packageName);
        }
        break;
      default:
        break;
    }
  }

  Future<void> setBlockedApps(List<String> packages) async {
    try {
      await _channel.invokeMethod('setBlockedApps', {'packages': packages});
    } on PlatformException catch (_) {
      // Failed to sync
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
    } on PlatformException catch (_) {
      // Failed to open settings
    }
  }

  Future<void> openAutostartSettings() async {
    try {
      const appsChannel = MethodChannel('com.muslimlauncher/apps');
      await appsChannel.invokeMethod('openAutostartSettings');
    } on PlatformException catch (_) {
      // Fallback
    }
  }

  Future<void> allowAppTemporarily(String packageName, {int durationMinutes = 60}) async {
    try {
      await _channel.invokeMethod('allowAppTemporarily', {
        'packageName': packageName,
        'durationMillis': durationMinutes * 60 * 1000,
      });
    } on PlatformException catch (_) {
      // Failed to allow app
    }
  }

  Future<void> setGhadhulBasharPackages(List<String> packages) async {
    try {
      await _channel.invokeMethod('setGhadhulBasharPackages', {'packages': packages});
    } on PlatformException catch (_) {
      // Failed to sync
    }
  }

  Future<void> allowGhadhulBasharSession(String packageName) async {
    try {
      await _channel.invokeMethod('allowGhadhulBasharSession', {
        'packageName': packageName,
      });
    } on PlatformException catch (_) {
      // Failed to allow session
    }
  }

  Future<void> resetGhadhulBasharSession(String packageName) async {
    try {
      await _channel.invokeMethod('resetGhadhulBasharSession', {
        'packageName': packageName,
      });
    } on PlatformException catch (_) {
      // Failed to reset session
    }
  }

  Future<void> setProhibitedPackages(List<String> packages) async {
    try {
      await _channel.invokeMethod('setProhibitedPackages', {'packages': packages});
    } on PlatformException catch (_) {
      // Failed to sync
    }
  }
}
