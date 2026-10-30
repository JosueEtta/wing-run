import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

TextStyle pixel(double size, {Color color = C.navy}) =>
    GoogleFonts.pressStart2p(fontSize: size, color: color, height: 1.3);

TextStyle body(double size, {Color color = C.navy}) =>
    GoogleFonts.vt323(fontSize: size, color: color);

/// Hard edges, thick dark outline, hard offset shadow.
BoxDecoration pixelBox({Color color = Colors.white, double shadow = 4}) =>
    BoxDecoration(
      color: color,
      border: Border.all(color: C.navy, width: 3),
      boxShadow: shadow == 0
          ? null
          : [BoxShadow(color: C.navy, offset: Offset(shadow, shadow))],
    );