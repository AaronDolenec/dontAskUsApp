import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  // Durations
  static const Duration micro = Duration(milliseconds: 140);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 280);
  static const Duration page = Duration(milliseconds: 320);

  // Curves
  static const Curve inCurve = Curves.easeInCubic;
  static const Curve outCurve = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve hover = Curves.easeOutQuart;
}
