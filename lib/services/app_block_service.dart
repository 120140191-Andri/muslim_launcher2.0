import 'package:flutter/services.dart';

class AppBlockService {
  static const MethodChannel _channel = MethodChannel('com.muslimlauncher/block');
  
  static final AppBlockService _instance = AppBlockService._internal();
  factory AppBlockService() => _instance;
  AppBlockService._internal();

  Function(String)? _onAppBlocked;
  Function(String)? _onGhadhulBasharTriggered;
  Function(String)? _onProhibitedAppTriggered;
  Function(String)? _onStrictShieldTriggered;

  void init({
    required Function(String) onAppBlocked,
    Function(String)? onGhadhulBasharTriggered,
    Function(String)? onProhibitedAppTriggered,
    Function(String)? onStrictShieldTriggered,
  }) {
    _onAppBlocked = onAppBlocked;
    _onGhadhulBasharTriggered = onGhadhulBasharTriggered;
    _onProhibitedAppTriggered = onProhibitedAppTriggered;
    _onStrictShieldTriggered = onStrictShieldTriggered;
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
      case 'onStrictShieldTriggered':
        final String? reason = call.arguments?['reason'];
        if (reason != null && _onStrictShieldTriggered != null) {
          _onStrictShieldTriggered!(reason);
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

  Future<void> prepareSupportDeveloperBypass() async {
    try {
      await _channel.invokeMethod('prepareSupportDeveloperBypass');
    } on PlatformException catch (_) {
      // Failed to arm bypass
    }
  }

  Future<void> setProhibitedPackages(List<String> packages) async {
    try {
      await _channel.invokeMethod('setProhibitedPackages', {'packages': packages});
    } on PlatformException catch (_) {
      // Failed to sync
    }
  }

  Future<bool> isDeviceAdminActive() async {
    try {
      final bool? active = await _channel.invokeMethod('isDeviceAdminActive');
      return active ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } on PlatformException catch (_) {
      // Failed to request
    }
  }

  Future<void> setStrictModeConfig({
    required bool enabled,
    required int days,
    required int untilMs,
  }) async {
    try {
      await _channel.invokeMethod('setStrictModeConfig', {
        'enabled': enabled,
        'days': days,
        'untilMs': untilMs,
      });
    } on PlatformException catch (_) {
      // Failed to configure
    }
  }

  Future<Map<String, dynamic>> getStrictModeStatus() async {
    try {
      final res = await _channel.invokeMethod('getStrictModeStatus');
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {};
    } on PlatformException catch (_) {
      return {};
    }
  }
}
