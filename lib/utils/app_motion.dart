import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  // Durations
  static const Duration micro = Duration(milliseconds: 160);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration standard = Duration(milliseconds: 300);

  // Curves
  static const Curve inCurve = Curves.easeIn;
  static const Curve outCurve = Curves.easeOut;
  static const Curve emphasized = Curves.easeOutCubic;
}
