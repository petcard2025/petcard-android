import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño de PetCard, calcado de `frontend/src/shared.css`
/// (la web), para que el look de la app móvil sea lo más parecido
/// posible al de la web.
///
/// Paleta y tokens tomados literalmente de las variables :root de
/// shared.css:
///   --purple / --purple-dark / --purple-light / --purple-bg
///   --green / --green-bg, --yellow / --yellow-bg, --red / --red-bg
///   --text, --text-secondary, --muted, --border, --bg, --white
///   --card-shadow, --radius, --radius-sm, --radius-lg
class AppTheme {
  AppTheme._();

  // ── COLORES (idénticos a :root en shared.css) ──────────────────
  static const Color blue = Color(0xFF2563EB); // --purple
  static const Color blueDark = Color(0xFF1D4ED8); // --purple-dark
  static const Color blueLight = Color(0xFF3B82F6); // --purple-light
  static const Color blueBg = Color(0xFFEFF6FF); // --purple-bg

  static const Color green = Color(0xFF16A34A);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color yellow = Color(0xFFCA8A04);
  static const Color yellowBg = Color(0xFFFEF9C3);
  static const Color red = Color(0xFFDC2626);
  static const Color redBg = Color(0xFFFEE2E2);
  static const Color orange = Color(0xFFEA580C);

  static const Color text = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color muted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color bg = Color(0xFFF3F4F6);
  static const Color white = Color(0xFFFFFFFF);

  // ── RADIOS (idénticos a --radius / --radius-sm / --radius-lg) ──
  static const double radius = 10;
  static const double radiusSm = 6;
  static const double radiusLg = 14;

  // ── SOMBRA DE TARJETA (--card-shadow: 0 2px 12px rgba(0,0,0,.08)) ─
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  // ── DECORACIÓN DE TARJETA LISTA PARA USAR ───────────────────────
  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
    color: color ?? white,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: border),
    boxShadow: cardShadow,
  );

  // ── TIPOGRAFÍA ───────────────────────────────────────────────────
  // Web: font-family 'Lato' para cuerpo de texto normal.
  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.normal,
    Color color = text,
    double? height,
  }) =>
      GoogleFonts.lato(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  // Web: font-family 'Nunito', usado en .nav-logo / .card-title
  // (encabezados, títulos de pantalla, títulos de tarjeta).
  static TextStyle heading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w800,
    Color color = text,
  }) =>
      GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  // ── THEMEDATA GLOBAL ─────────────────────────────────────────────
  static ThemeData get themeData {
    final baseTextTheme = GoogleFonts.latoTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      primaryColor: blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        primary: blue,
        secondary: blueLight,
        surface: white,
      ),
      textTheme: baseTextTheme.copyWith(
        // Los títulos grandes usan Nunito, igual que .nav-logo/.card-title
        headlineLarge: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: text),
        headlineMedium: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: text),
        headlineSmall: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: text),
        titleLarge: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: text),
        titleMedium: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: text),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: blue,
        ),
        iconTheme: const IconThemeData(color: blue),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: white,
          textStyle: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blue,
          side: const BorderSide(color: blue, width: 1.5),
          textStyle: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
      ),
    );
  }
}