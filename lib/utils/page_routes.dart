import 'package:flutter/material.dart';

/// Custom page route with fade transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route with slide up transition
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route with slide from right transition
class SlideRightPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideRightPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            var fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route with scale transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutCubic;

            var scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );

            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom hero page route
class HeroPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  HeroPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Extension for easy navigation with custom routes
extension NavigatorExtension on NavigatorState {
  Future<T?> pushFade<T>(Widget page) {
    return push(FadePageRoute<T>(page: page));
  }

  Future<T?> pushSlideUp<T>(Widget page) {
    return push(SlideUpPageRoute<T>(page: page));
  }

  Future<T?> pushSlideRight<T>(Widget page) {
    return push(SlideRightPageRoute<T>(page: page));
  }

  Future<T?> pushScale<T>(Widget page) {
    return push(ScalePageRoute<T>(page: page));
  }

  Future<T?> pushHero<T>(Widget page) {
    return push(HeroPageRoute<T>(page: page));
  }
}
