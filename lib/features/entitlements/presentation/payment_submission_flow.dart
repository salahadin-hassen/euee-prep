import 'package:flutter/material.dart';

import 'steps/step1_confirm_purchase.dart';
import 'steps/step2_payment_instructions.dart';
import 'steps/step3_submit_proof.dart';
import 'steps/step4_confirmation.dart';

/// Coordinates the 4-step Payment Submission flow (Decision 013).
///
/// Presentation-layer only. Holds transient UI state (current step,
/// transaction ID text, a mocked "screenshot attached" flag) — none of
/// this is persisted or validated against real business rules here.
///
/// TODO(integration): Replace the mocked submit behavior in
/// [_handleSubmit] with a real call through the application/service
/// layer once available. The step widgets themselves should not need to
/// change — only what happens inside these handler methods.
class PaymentSubmissionFlow extends StatefulWidget {
  const PaymentSubmissionFlow({
    super.key,
    required this.streamName,
    this.onFlowComplete,
  });

  /// Pre-selected stream, e.g. carried over from a rejected
  /// PaymentRequestCard's "Submit New Payment" action, or null for the
  /// global entry point (Payment History's bottom CTA).
  final String streamName;

  /// TODO(integration): wire to Payment History navigation.
  final VoidCallback? onFlowComplete;

  @override
  State<PaymentSubmissionFlow> createState() => _PaymentSubmissionFlowState();
}

class _PaymentSubmissionFlowState extends State<PaymentSubmissionFlow> {
  int _currentStep = 1;

  bool _isScreenshotAttached = false;
  final _transactionIdController = TextEditingController();

  final bool _isOffline =
      false; // TODO(integration): drive from real connectivity state.
  String? _submitError;
  String? _submittedRequestId;

  static const _subjectsByStream = {
    'Natural Science': [
      'English',
      'Mathematics',
      'SAT (Aptitude)',
      'Physics',
      'Chemistry',
      'Biology',
    ],
    'Social Science': [
      'English',
      'Mathematics',
      'SAT (Aptitude)',
      'Geography',
      'History',
      'Economics',
    ],
  };

  @override
  void dispose() {
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (_currentStep == 3 &&
        (_isScreenshotAttached ||
            _transactionIdController.text.trim().isNotEmpty)) {
      final shouldDiscard = await _confirmDiscard();
      if (shouldDiscard != true) return;
    }
    setState(() => _currentStep -= 1);
  }

  Future<bool?> _confirmDiscard() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this submission?'),
        content: const Text(
          "Your attached screenshot and transaction ID won't be saved "
          'if you go back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _submitError = null);

    // TODO(integration): replace with a real submission call. Simulated
    // here so the confirmation step is reachable and reviewable.
    if (_isOffline)
      return; // step screen already blocks this via disabled button

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _submittedRequestId =
          'EP-${DateTime.now().millisecondsSinceEpoch % 10000}';
      _currentStep = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _subjectsByStream[widget.streamName] ?? const [];

    return PopScope(
      canPop: _currentStep == 1,
      onPopInvoked: (didPop) {
        if (!didPop && _currentStep > 1) _handleBack();
      },
      child: switch (_currentStep) {
        1 => Step1ConfirmPurchase(
            streamName: widget.streamName,
            subjects: subjects,
            priceLabel: '200 ETB (one-time)',
            onContinue: () => setState(() => _currentStep = 2),
          ),
        2 => Step2PaymentInstructions(
            priceLabel: '200 ETB',
            payToNumber: '0912 345 678',
            payToName: 'EUEE Prep',
            onContinue: () => setState(() => _currentStep = 3),
            onBack: _handleBack,
          ),
        3 => Step3SubmitProof(
            isScreenshotAttached: _isScreenshotAttached,
            transactionIdController: _transactionIdController,
            isOffline: _isOffline,
            submitError: _submitError,
            onAttachScreenshot: () =>
                setState(() => _isScreenshotAttached = true),
            onRemoveScreenshot: () =>
                setState(() => _isScreenshotAttached = false),
            onSubmit: _handleSubmit,
            onBack: _handleBack,
          ),
        _ => Step4Confirmation(
            requestId: _submittedRequestId ?? '—',
            onViewPaymentStatus: widget.onFlowComplete ?? () {},
            onDone: widget.onFlowComplete ?? () {},
          ),
      },
    );
  }
}
