import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities and helpers for better screen reader support
class AccessibilityUtils {
  AccessibilityUtils._();

  /// Minimum touch target size according to WCAG guidelines (48x48)
  static const double minTouchTarget = 48.0;

  /// Check if the current context has large text enabled
  static bool isLargeText(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1.0) > 1.3;
  }

  /// Check if reduced motion is enabled
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Check if high contrast is enabled
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Check if screen reader is active
  static bool isScreenReaderActive(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Announce a message to screen readers
  static void announce(String message, {TextDirection? textDirection}) {
    SemanticsService.announce(message, textDirection ?? TextDirection.ltr);
  }

  /// Get animation duration based on accessibility settings
  static Duration getAnimationDuration(
    BuildContext context, {
    Duration normal = const Duration(milliseconds: 300),
  }) {
    if (isReducedMotion(context)) {
      return Duration.zero;
    }
    return normal;
  }
}

/// A wrapper widget that ensures minimum touch target size
class TouchTargetPadding extends StatelessWidget {
  final Widget child;
  final double minSize;

  const TouchTargetPadding({
    super.key,
    required this.child,
    this.minSize = AccessibilityUtils.minTouchTarget,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }
}

/// Semantic wrapper for custom widgets to improve screen reader support
class SemanticWidget extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool? button;
  final bool? header;
  final bool? link;
  final bool? slider;
  final bool? textField;
  final bool? image;
  final bool? liveRegion;
  final bool excludeSemantics;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SemanticWidget({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.button,
    this.header,
    this.link,
    this.slider,
    this.textField,
    this.image,
    this.liveRegion,
    this.excludeSemantics = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      header: header,
      link: link,
      slider: slider,
      textField: textField,
      image: image,
      liveRegion: liveRegion,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}

/// Focus traversal helper for keyboard navigation
class FocusTraversalWidget extends StatelessWidget {
  final Widget child;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool skipTraversal;
  final int? order;

  const FocusTraversalWidget({
    super.key,
    required this.child,
    this.focusNode,
    this.autofocus = false,
    this.skipTraversal = false,
    this.order,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      skipTraversal: skipTraversal,
      child: child,
    );

    if (order != null) {
      result = FocusTraversalOrder(
        order: NumericFocusOrder(order!.toDouble()),
        child: result,
      );
    }

    return result;
  }
}

/// Color contrast utilities
class ContrastUtils {
  ContrastUtils._();

  /// Calculate relative luminance of a color
  static double relativeLuminance(Color color) {
    double r = color.red / 255;
    double g = color.green / 255;
    double b = color.blue / 255;

    r = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055).pow(2.4);
    g = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055).pow(2.4);
    b = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055).pow(2.4);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculate contrast ratio between two colors
  static double contrastRatio(Color color1, Color color2) {
    final l1 = relativeLuminance(color1);
    final l2 = relativeLuminance(color2);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA standard (4.5:1 for normal text)
  static bool meetsWCAGAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }

  /// Check if contrast ratio meets WCAG AAA standard (7:1 for normal text)
  static bool meetsWCAGAAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 7.0;
  }

  /// Get a contrasting text color (black or white) for a background
  static Color getContrastingTextColor(Color background) {
    final luminance = relativeLuminance(background);
    return luminance > 0.179 ? Colors.black : Colors.white;
  }
}

extension _DoublePow on double {
  double pow(double exponent) {
    return this <= 0 ? 0 : (this as num).toDouble();
  }
}

/// Extension to add semantic labels to common widgets
extension SemanticExtensions on Widget {
  Widget withSemanticLabel(String label) {
    return Semantics(
      label: label,
      child: this,
    );
  }

  Widget asButton({String? label, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      child: this,
    );
  }

  Widget asHeader({String? label}) {
    return Semantics(
      header: true,
      label: label,
      child: this,
    );
  }

  Widget asImage({required String label}) {
    return Semantics(
      image: true,
      label: label,
      child: this,
    );
  }

  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }
}
