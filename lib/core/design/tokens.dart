// TODO(design-system): This file is a MINIMAL PLACEHOLDER, not the real
// Milestone 4 implementation of core/design/. It exists only so that
// features/entitlements/presentation can compile and be reviewed in
// isolation, per 06_DESIGN_SYSTEM.md's token contract (Decision 018).
//
// Do not treat these hex values / font sizes as final brand decisions —
// 06_DESIGN_SYSTEM.md explicitly marks colors and typography as
// placeholders. When Milestone 4 lands, this file should be replaced by
// the real core/design/colors.dart, typography.dart, spacing.dart,
// radius.dart, animations.dart — call sites in this feature should not
// need to change, only the values imported here.

import 'package:flutter/material.dart';

/// Color tokens — names fixed by 06_DESIGN_SYSTEM.md.
class AppColors {
  AppColors._();

  static const Color colorPrimary = Color(0xFF2F6F4F);
  static const Color colorSecondary = Color(0xFF3C7A89);
  static const Color colorBackground = Color(0xFFF7F7F5);
  static const Color colorSurface = Color(0xFFFFFFFF);
  static const Color colorError = Color(0xFFB3261E);
  static const Color colorSuccess = Color(0xFF2E7D32);
  static const Color colorWarning = Color(0xFFB8860B);
  static const Color colorTextPrimary = Color(0xFF1B1B1B);
  static const Color colorTextSecondary = Color(0xFF6B6B6B);
  static const Color colorBorder = Color(0xFFE0E0E0);
  static const Color colorDisabled = Color(0xFFBDBDBD);
}

/// Typography tokens — names fixed by 06_DESIGN_SYSTEM.md.
/// Font family left as system default per the contract (no brand font yet).
class AppTypography {
  AppTypography._();

  static const TextStyle typeDisplay = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle typeHeading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle typeHeading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle typeHeading3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle typeBody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.colorTextPrimary,
  );

  static const TextStyle typeCaption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.colorTextSecondary,
  );

  static const TextStyle typeButtonLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
}

/// Spacing tokens (px/dp) — values fixed by 06_DESIGN_SYSTEM.md.
class AppSpacing {
  AppSpacing._();

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;
}

/// Radius tokens — values fixed by 06_DESIGN_SYSTEM.md.
class AppRadius {
  AppRadius._();

  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 16;
  static const double radiusFull = 999;
}

/// Stroke/border-width tokens — proposed addition (flagged during the
/// Payment History design review) so the card left-accent border has a
/// named token instead of a hardcoded magic number at the call site.
/// Awaiting product sign-off to fold into 06_DESIGN_SYSTEM.md formally.
class AppStroke {
  AppStroke._();

  static const double strokeThin = 1;
  static const double strokeAccent = 4;
}

/// Animation duration tokens — values fixed by 06_DESIGN_SYSTEM.md.
class AppDuration {
  AppDuration._();

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
}

/// Icon size scale — proposed addition (flagged during Payment
/// Submission design review) for consistent "large calm icon" sizing
/// across confirmation/empty states. Awaiting product sign-off.
class AppIconSize {
  AppIconSize._();

  static const double iconSizeSm = 16;
  static const double iconSizeMd = 24;
  static const double iconSizeLg = 32;
  static const double iconSizeXl = 64;
}
