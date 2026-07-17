import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Lowpoly's design tokens. Change values here, not scattered across screens.
class LowpolyColors {
  LowpolyColors._();

  static const bgTop = Color(0xFF160B33);
  static const bgBottom = Color(0xFF241147);

  static const surface = Color(0xFF241748);
  static const surfaceShadow = Color(0xFF150B2C); // the "pressed slab" beneath cards

  static const primary = Color(0xFF8C6BFF); // X, primary actions
  static const primaryShadow = Color(0xFF5A3FCC);

  static const secondary = Color(0xFFFF8A5B); // O
  static const secondaryShadow = Color(0xFFCC5E32);

  static const win = Color(0xFFC6FF5E);
  static const draw = Color(0xFFFFD166);
  static const lose = Color(0xFFFF6B81);

  static const textPrimary = Color(0xFFF5F1FF);
  static const textMuted = Color(0xFFB8AFD9);
}

class LowpolyTextStyles {
  LowpolyTextStyles._();

  static TextStyle display({double size = 32, Color? color, FontWeight? weight}) =>
      GoogleFonts.baloo2(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? LowpolyColors.textPrimary,
      );

  static TextStyle body({double size = 16, Color? color, FontWeight? weight}) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w600,
        color: color ?? LowpolyColors.textPrimary,
      );
}

ThemeData buildLowpolyTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: LowpolyColors.bgTop,
    colorScheme: ColorScheme.fromSeed(
      seedColor: LowpolyColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: LowpolyColors.primary,
      secondary: LowpolyColors.secondary,
      surface: LowpolyColors.surface,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: LowpolyColors.textPrimary,
      displayColor: LowpolyColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: LowpolyTextStyles.display(size: 22),
      iconTheme: const IconThemeData(color: LowpolyColors.textPrimary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LowpolyColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: LowpolyTextStyles.body(size: 16, weight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LowpolyColors.textPrimary,
        side: const BorderSide(color: LowpolyColors.primary, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: LowpolyTextStyles.body(size: 15, weight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LowpolyColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      hintStyle: LowpolyTextStyles.body(size: 15, color: LowpolyColors.textMuted, weight: FontWeight.w600),
      labelStyle: LowpolyTextStyles.body(size: 15, color: LowpolyColors.textMuted, weight: FontWeight.w600),
    ),
  );
}

/// The app's signature background: a soft top-to-bottom violet gradient
/// used behind every screen instead of a flat scaffold color.
class LowpolyBackground extends StatelessWidget {
  final Widget child;
  const LowpolyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [LowpolyColors.bgTop, LowpolyColors.bgBottom],
        ),
      ),
      child: child,
    );
  }
}
