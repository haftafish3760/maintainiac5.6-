import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Route<T> appNativeRoute<T>(BuildContext context, Widget screen) {
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return CupertinoPageRoute<T>(builder: (_) => screen);
  }
  return MaterialPageRoute<T>(builder: (_) => screen);
}

Route<T> appSlideRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final position = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(position: animation.drive(position), child: child);
    },
  );
}

Route<T> appDrawerRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final position = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      final fade = Tween<double>(
        begin: 0,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOut));

      return FadeTransition(
        opacity: animation.drive(fade),
        child: SlideTransition(
          position: animation.drive(position),
          child: child,
        ),
      );
    },
  );
}

class AppSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const AppSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == Navigator.defaultRouteName) {
      return child;
    }

    final position = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    final fade = Tween<double>(
      begin: 0.92,
      end: 1,
    ).chain(CurveTween(curve: Curves.easeOut));

    return FadeTransition(
      opacity: animation.drive(fade),
      child: SlideTransition(position: animation.drive(position), child: child),
    );
  }
}
