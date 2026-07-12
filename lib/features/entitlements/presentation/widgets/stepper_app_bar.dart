import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// App bar for a multi-step flow: title, back action, and a "n/total"
/// step indicator.
///
/// Built generic enough to reuse for any future multi-step flow (e.g.
/// onboarding), not special-cased to payments.
class StepperAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StepperAppBar({
    super.key,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
    this.onBack,
  });

  final String title;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final stepLabel = '$currentStep/$totalSteps';
    return Semantics(
      label: '$title, step $stepLabel',
      excludeSemantics: true,
      child: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: Text(title, style: AppTypography.typeHeading3),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.spaceMd),
            child: Center(
              child: Text(stepLabel, style: AppTypography.typeCaption),
            ),
          ),
        ],
      ),
    );
  }
}
