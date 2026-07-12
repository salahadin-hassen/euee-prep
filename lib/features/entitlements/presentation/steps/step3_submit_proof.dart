import 'package:flutter/material.dart';

import '../../../../core/design/app_button.dart';
import '../../../../core/design/app_text_field.dart';
import '../../../../core/design/tokens.dart';
import '../widgets/proof_upload_field.dart';
import '../widgets/stepper_app_bar.dart';

/// Step 3 — Submit Proof.
///
/// The riskiest step for downstream rejection, so:
/// - Submit is disabled until at least one proof field has content.
/// - A soft (non-blocking) tip nudges toward adding both screenshot AND
///   transaction ID when only one is present.
/// - Offline state blocks submission with an explanatory message
///   BEFORE the student loses their input (Decision 013 requires
///   connectivity for this step) — entered data is preserved either way.
class Step3SubmitProof extends StatelessWidget {
  const Step3SubmitProof({
    super.key,
    required this.isScreenshotAttached,
    required this.transactionIdController,
    required this.isOffline,
    required this.submitError,
    required this.onAttachScreenshot,
    required this.onRemoveScreenshot,
    required this.onSubmit,
    this.onBack,
  });

  final bool isScreenshotAttached;
  final TextEditingController transactionIdController;
  final bool isOffline;

  /// Non-null when a previous submit attempt failed — preserved data,
  /// shown as an inline banner rather than clearing the form.
  final String? submitError;

  final VoidCallback onAttachScreenshot;
  final VoidCallback onRemoveScreenshot;
  final VoidCallback onSubmit;
  final VoidCallback? onBack;

  bool get _hasAnyProof =>
      isScreenshotAttached || transactionIdController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final canSubmit = _hasAnyProof && !isOffline;

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: StepperAppBar(
        title: 'Submit Proof',
        currentStep: 3,
        totalSteps: 4,
        onBack: onBack,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOffline) _OfflineNotice(),
              if (submitError != null) _ErrorBanner(message: submitError!),
              Text('Screenshot of payment', style: AppTypography.typeBody),
              const SizedBox(height: AppSpacing.spaceSm),
              ProofUploadField(
                isAttached: isScreenshotAttached,
                onTap: onAttachScreenshot,
                onRemove: onRemoveScreenshot,
              ),
              const SizedBox(height: AppSpacing.spaceLg),
              Text(
                'Transaction ID (optional if screenshot is clear)',
                style: AppTypography.typeBody,
              ),
              const SizedBox(height: AppSpacing.spaceSm),
              AppTextField(
                controller: transactionIdController,
                hintText: 'e.g. TB123456789',
              ),
              if (isScreenshotAttached &&
                  transactionIdController.text.trim().isEmpty) ...[
                const SizedBox(height: AppSpacing.spaceSm),
                Text(
                  'Tip: also adding the transaction ID text helps us '
                  'verify faster.',
                  style: AppTypography.typeCaption,
                ),
              ],
              const Spacer(),
              AppButton(
                label: 'Submit',
                isFullWidth: true,
                onPressed: canSubmit ? onSubmit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.colorWarning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      child: Text(
        "You're offline. Connect to the internet to submit your payment "
        "proof — your screenshot and details are saved and won't be lost.",
        style: AppTypography.typeBody.copyWith(color: AppColors.colorWarning),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.colorError.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      child: Text(
        message,
        style: AppTypography.typeBody.copyWith(color: AppColors.colorError),
      ),
    );
  }
}
