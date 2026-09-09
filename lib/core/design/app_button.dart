// TODO(design-system): MINIMAL PLACEHOLDER for Milestone 4's real
// core/design/buttons.dart. Implements the four variants named in
// 06_DESIGN_SYSTEM.md (primary, secondary, text, destructive) with no
// styling beyond the token contract, so features can compose against a
// real AppButton API now instead of ElevatedButton/TextButton directly.

import 'package:flutter/material.dart';
import 'tokens.dart';

enum AppButtonVariant { primary, secondary, text, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label, style: AppTypography.typeButtonLabel)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.iconSizeMd),
              const SizedBox(width: AppSpacing.spaceSm),
              Text(label, style: AppTypography.typeButtonLabel),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.colorPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.colorDisabled,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spaceLg,
              vertical: AppSpacing.spaceMd,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            ),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.colorPrimary,
            side: const BorderSide(color: AppColors.colorPrimary),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spaceLg,
              vertical: AppSpacing.spaceMd,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            ),
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.colorPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spaceMd,
              vertical: AppSpacing.spaceSm,
            ),
          ),
          child: child,
        ),
      AppButtonVariant.destructive => ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.colorError,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.colorDisabled,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spaceLg,
              vertical: AppSpacing.spaceMd,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            ),
          ),
          child: child,
        ),
    };

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
