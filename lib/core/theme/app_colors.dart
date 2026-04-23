import 'package:flutter/material.dart';

/// NUMBAA color palette — Orange brand + complementary accents.
class AppColors {
  AppColors._();

  // Primary — Orange brand
  static const Color primary = Color(0xFFFF7900);
  static const Color primaryDark = Color(0xFFE06800);
  static const Color primaryLight = Color(0xFFFFF3E0);

  // Secondary — deep charcoal (replaces pure black for softer feel)
  static const Color secondary = Color(0xFF1A1A2E);

  // Complementary — Blue (used for dashboard header, SMS)
  static const Color blue = Color(0xFF1565C0);
  static const Color blueDark = Color(0xFF0D47A1);
  static const Color blueLight = Color(0xFFE3F2FD);

  // Complementary — Teal/Green (used for success, campaigns, WhatsApp)
  static const Color green = Color(0xFF00796B);
  static const Color greenLight = Color(0xFFE0F2F1);

  // Complementary — Purple (used for mini-site, premium)
  static const Color purple = Color(0xFF6A1B9A);
  static const Color purpleLight = Color(0xFFF3E5F5);

  // Amber — notification badge, urgency
  static const Color amber = Color(0xFFFFB300);

  // Dashboard header — Orange gradient (brand primary)
  static const Color dashboardHeader = Color(0xFFFF7900);
  static const Color dashboardHeaderDark = Color(0xFFE06800);

  // Neutrals — warm grays
  static const Color neutralDark = Color(0xFF2D2D2D);
  static const Color neutralMid = Color(0xFF757575);
  static const Color neutralLight = Color(0xFFF5F5F5);

  // Surfaces — warm white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F8F8);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Semantic
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);

  // Borders & dividers — softer
  static const Color divider = Color(0xFFEEEEEE);
  static const Color border = Color(0xFFE0E0E0);
}
