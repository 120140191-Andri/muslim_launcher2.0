import 'package:flutter/material.dart';

/// Material Design 3 Expressive page route utilizing Theme's ZoomPageTransitionsBuilder.
class AppPageRoute<T> extends MaterialPageRoute<T> {
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
