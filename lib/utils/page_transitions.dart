import 'package:flutter/cupertino.dart';

/// iOS-standard smooth Cupertino page route with hardware-accelerated glide and native swipe-back.
class AppPageRoute<T> extends CupertinoPageRoute<T> {
  AppPageRoute({
    required Widget child,
    RouteSettings? settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
  }) : super(
          builder: (context) => child,
          settings: settings ?? RouteSettings(name: child.runtimeType.toString()),
        );
}
