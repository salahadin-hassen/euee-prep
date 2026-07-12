import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../models/payment_request_ui_model.dart';

/// Compact icon + label indicating one of the five payment pipeline
/// states (Decision 013 + rejected state addition).
///
/// Design rule: color is never the sole carrier of meaning here — every
/// state pairs a distinct icon shape with its color, so the badge remains
/// legible for colorblind users (see Accessibility Review in the design
/// spec).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final PaymentRequestStatus status;

  _StatusBadgeConfig get _config => switch (status) {
        PaymentRequestStatus.submitted => const _StatusBadgeConfig(
            icon: Icons.schedule_outlined,
            color: AppColors.colorTextSecondary,
            label: 'Received',
          ),
        PaymentRequestStatus.pending => const _StatusBadgeConfig(
            icon: Icons.schedule,
            color: AppColors.colorWarning,
            label: 'Pending review',
          ),
        PaymentRequestStatus.verified => const _StatusBadgeConfig(
            icon: Icons.check_circle_outline,
            color: AppColors.colorWarning,
            label: 'Verified — finishing setup',
          ),
        PaymentRequestStatus.entitled => const _StatusBadgeConfig(
            icon: Icons.check_circle,
            color: AppColors.colorSuccess,
            label: 'Content unlocked',
          ),
        PaymentRequestStatus.rejected => const _StatusBadgeConfig(
            icon: Icons.cancel_outlined,
            color: AppColors.colorError,
            label: 'Not approved',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Semantics(
      // Single coherent phrase for screen readers rather than a
      // fragmented icon + text read separately.
      label: 'Payment status: ${config.label}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: AppIconSize.iconSizeMd, color: config.color),
          const SizedBox(width: AppSpacing.spaceXs),
          Text(
            config.label,
            style: AppTypography.typeCaption.copyWith(color: config.color),
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeConfig {
  const _StatusBadgeConfig({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}
