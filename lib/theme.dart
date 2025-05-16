import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF3498DB);
  static const Color secondaryColor = Color.fromARGB(255, 0, 21, 255);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E2330);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color successColor = Color(0xFF2ECC71);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color errorColor = Color(0xFFE74C3C);

  static TextStyle headingStyle = GoogleFonts.montserrat(
    color: textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 20,
  );

  static TextStyle subheadingStyle = GoogleFonts.montserrat(
    color: textPrimary,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  static TextStyle bodyStyle = GoogleFonts.montserrat(
    color: textSecondary,
    fontSize: 14,
  );
}
