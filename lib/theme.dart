import 'package:flutter/material.dart';

class C {
  static const red = Color(0xFFDC2626);
  static const blue = Color(0xFF2563EB);
  static const lightBlue = Color(0xFF60A5FA);
  static const navy = Color(0xFF0F172A);
  static const green = Color(0xFF15803D);
  static const slate = Color(0xFFF1F5F9);
  static const gold = Color(0xFFEAB308);
  static const silver = Color(0xFF94A3B8);
  static const bronze = Color(0xFFB45309);
  static const highlight = Color(0xFFDBEAFE);
}

TextStyle pixel(double size, {Color color = C.navy}) => TextStyle(
  fontFamily: 'PressStart2P',
  fontSize: size,
  color: color,
  height: 1.3,
);

TextStyle body(double size, {Color color = C.navy}) => TextStyle(
  fontFamily: 'VT323',
  fontSize: size,
  color: color,
);

/// Flat box: thick dark outline, no shadow.
///
/// [shadow] is kept only so existing calls such as `pixelBox(shadow: 6)`
/// still compile. It is ignored: the app has no shadows now.
BoxDecoration pixelBox({Color color = Colors.white, double shadow = 0}) =>
    BoxDecoration(
      color: color,
      border: Border.all(color: C.navy, width: 3),
    );