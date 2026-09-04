import 'package:flutter/material.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import 'mock/mock_payment_requests.dart';
import 'models/payment_request_ui_model.dart';
import 'payment_submission_flow.dart';
import 'widgets/empty_payment_state.dart';
import 'widgets/payment_request_card.dart';

/// Payment History screen (Decision 013/023).
///
/// Presentation-layer only. All data currently comes from
/// [MockPaymentRequests]; refresh/loading/offline behavior here is local
/// UI state for demo purposes, standing in for what a real provider
/// (Riverpod) will eventually drive.
///
/// TODO(integration): Replace the mock data calls and local _isLoading /
/// _isOffline state with a real provider, e.g.:
///   final asyncRequests = ref.watch(paymentRequestListProvider);
/// The widget tree below (ListView.separated + PaymentRequestCard +
/// EmptyPaymentState) should not need structural changes — only the
/// data source and loading/error state source change.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  final bool _isOffline = false; // TODO(integration): drive from real connectivity state.
  List<PaymentRequestUiModel> _requests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    // Simulated latency so the skeleton state is visible during review.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _requests = MockPaymentRequests.all();
      _isLoading = false;
    });
  }

  Future<void> _handleRefresh() async {
    // Manual refresh — Decision 013 explicitly scopes MVP to
    // user-initiated sync, not real-time push.
    await _load();
  }

  /// Pushes the Payment Submission flow, optionally pre-filling a
  /// stream (e.g. when re-submitting from a rejected card). Pops back
  /// to this screen and refreshes once the flow reports completion.
  ///
  /// TODO(integration): a real navigation layer (go_router or similar)
  /// will likely own named routes for this instead of a direct
  /// Navigator.push — this is a presentation-only stand-in so the two
  /// screens are actually reachable from each other during review.
  Future<void> _openSubmissionFlow({String? preselectedStream}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentSubmissionFlow(
          streamName: preselectedStream ?? 'Natural Science',
          onFlowComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
    // Refresh so a newly-submitted request appears in the list.
    await _load();
  }

  /// TODO(integration): remove once real navigation to the Subjects
  /// feature exists. This exists only so tapping these buttons gives
  /// visible feedback instead of appearing broken/unresponsive.
  void _showComingSoon(String destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$destination is not implemented yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: const Text('Payment History', style: AppTypography.typeHeading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isOffline ? null : _handleRefresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isOffline) const _OfflineBanner(),
            Expanded(child: _buildBody()),
            if (!_isLoading && _requests.isNotEmpty) _buildBottomCta(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const _PaymentHistorySkeleton();

    if (_requests.isEmpty) {
      return EmptyPaymentState(
        onBrowseSubjects: () => _showComingSoon('Subject list'),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.spaceMd),
        itemBuilder: (context, index) {
          final request = _requests[index];
          return PaymentRequestCard(
            request: request,
            onGoToSubjects: () => _showComingSoon('Subject list'),
            onSubmitNewPayment: () =>
                _openSubmissionFlow(preselectedStream: request.streamName),
          );
        },
      ),
    );
  }

  Widget _buildBottomCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceMd,
        0,
        AppSpacing.spaceMd,
        AppSpacing.spaceMd,
      ),
      child: AppButton(
        label: 'Submit New Payment',
        variant: AppButtonVariant.secondary,
        isFullWidth: true,
        onPressed: _openSubmissionFlow,
      ),
    );
  }
}

/// Inline banner shown when cached data is displayed because the device
/// is offline. Distinct from a full-screen error — the list still
/// renders from cache beneath it.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.colorWarning.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceMd,
        vertical: AppSpacing.spaceSm,
      ),
      child: Text(
        "You're offline — showing last known status.",
        style: AppTypography.typeCaption.copyWith(color: AppColors.colorWarning),
      ),
    );
  }
}

/// Skeleton loading state — three shimmer-shaped placeholder cards
/// matching PaymentRequestCard's footprint, per the design spec's
/// "never a centered spinner" rule.
class _PaymentHistorySkeleton extends StatelessWidget {
  const _PaymentHistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.spaceMd),
      itemBuilder: (context, index) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: AppColors.colorBorder),
      ),
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(width: 140, height: 16),
          const SizedBox(height: AppSpacing.spaceSm),
          _bar(width: 100, height: 12),
          const SizedBox(height: AppSpacing.spaceXs),
          _bar(width: 160, height: 12),
        ],
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.colorDisabled.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
    );
  }
}