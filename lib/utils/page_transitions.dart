import 'package:flutter/material.dart';

/// Instant zero-delay page route for maximum snappiness and low-spec performance.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  AppPageRoute({
    required this.child,
    RouteSettings? settings,
  }) : super(
          settings: settings ?? RouteSettings(name: child.runtimeType.toString()),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}

