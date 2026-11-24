import 'package:flutter/material.dart';

/// Colors taken from the Figma palette (BorrowCircle_UI.pdf).
class AppColors {
  AppColors._();

  // Primary (teal)
  static const primary = Color(0xFF0F766E);
  static const primaryHover = Color(0xFF0E6A63);
  static const primaryLight = Color(0xFFE7F1F1);
  static const primaryLightActive = Color(0xFFB5D5D2);

  // Secondary (green)
  static const secondary = Color(0xFF10B981);
  static const secondaryLight = Color(0xFFE7F8F2);

  // Tertiary (amber)
  static const tertiary = Color(0xFFF59E0B);
  static const tertiaryLight = Color(0xFFFEF5E7);
  static const tertiaryDark = Color(0xFFB87708);

  // Neutral
  static const background = Colors.white;
  static const surface = Color(0xFFEFF4F3); // segmented control background
  static const border = Color(0xFFE2EAE8);
  static const textDark = Color(0xFF052927); // "Primary darker" - used for titles
  static const textGrey = Color(0xFF5F7370);

  static const error = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFDECEC);

  /// Background + text color for a status chip.
  static (Color bg, Color fg) statusColors(String status) {
    switch (status) {
      case 'approved':
      case 'on_loan':
      case 'active':
      case 'returned':
        return (primaryLight, primary);
      case 'pending':
      case 'awaiting_handover':
        return (tertiaryLight, tertiaryDark);
      case 'rejected':
      case 'overdue':
        return (errorLight, error);
      default: // cancelled, unknown
        return (surface, textGrey);
    }
  }
}
