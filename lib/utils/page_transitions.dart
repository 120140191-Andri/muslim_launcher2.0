import 'package:flutter/material.dart';

/// Instant zero-delay page route with all animations disabled for maximum snappiness.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  AppPageRoute({
    required this.child,
    RouteSettings? settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
  }) : super(
          settings: settings ?? RouteSettings(name: child.runtimeType.toString()),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}

/// A zero-animation transitions builder for MaterialApp theme
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
