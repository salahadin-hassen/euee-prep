import 'package:flutter/material.dart';

import '../app_button.dart';
import '../tokens.dart';

/// One action button config for [ConfirmationScreen].
class ConfirmationAction {
  const ConfirmationAction({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
}

/// Generic full-screen "this succeeded" layout: large calm icon,
/// headline, optional detail widget slot, and up to two actions.
///
/// This is deliberately generic rather than payment-specific — the
/// design review flagged this pattern as worth reusing for any terminal
/// success moment (finishing an exam, completing onboarding), so
/// payment-specific content (Request ID, "what happens next" copy) is
/// passed in by the caller rather than hardcoded here.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    required this.headline,
    this.detail,
    this.actions = const [],
    this.icon = Icons.check_circle,
    this.iconColor = AppColors.colorSuccess,
  });

  final String headline;

  /// Optional widget shown between the headline and the actions —
  /// e.g. a CopyableField for a Request ID, or explanatory body text.
  final Widget? detail;

  final List<ConfirmationAction> actions;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppIconSize.iconSizeXl, color: iconColor),
                const SizedBox(height: AppSpacing.spaceLg),
                Text(
                  headline,
                  style: AppTypography.typeHeading1,
                  textAlign: TextAlign.center,
                ),
                if (detail != null) ...[
                  const SizedBox(height: AppSpacing.spaceMd),
                  detail!,
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.spaceXl),
                  for (final action in actions) ...[
                    AppButton(
                      label: action.label,
                      variant: action.variant,
                      onPressed: action.onPressed,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: AppSpacing.spaceSm),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
