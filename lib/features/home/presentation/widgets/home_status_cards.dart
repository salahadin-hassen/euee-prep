import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// Green-check row confirming how many papers are already on the device.
///
/// The app is offline-first (Decision 020) — imported content is local, so
/// the count is simply every paper imported for the stream.
class OfflineReadyRow extends StatelessWidget {
  const OfflineReadyRow({super.key, required this.paperCount});

  final int paperCount;

  @override
  Widget build(BuildContext context) {
    final noun = paperCount == 1 ? 'paper is' : 'papers are';
    return _surface(
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: AppIconSize.iconSizeMd,
            color: AppBrand.positive,
          ),
          const SizedBox(width: AppSpacing.spaceSm),
          Expanded(
            child: Text(
              '$paperCount $noun ready offline',
              style: AppTypography.typeBody.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navy unlock bar shown while the stream has no active entitlement.
///
/// Copy and price match the approved reference screen. Tapping it opens the
/// existing payment submission flow.
class UnlockBar extends StatelessWidget {
  const UnlockBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _surface(
      color: AppBrand.navy,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceMd,
        vertical: AppSpacing.spaceSm + 4,
      ),
      child: Semantics(
        button: true,
        label: 'Unlock all subjects, one-time payment, 200 birr',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.radiusCard),
          child: Row(
            children: [
              const Text('\u{1F513}', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unlock all subjects',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'One-time payment \u2022 200 birr',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppIconSize.iconSizeMd,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pale-blue pointer to the offline unlock walkthrough.
///
/// Deliberately not tappable: there is no video asset or playback path in
/// the app, so the row is rendered as the reference screen shows it but
/// carries no invented behaviour.
class UnlockVideoRow extends StatelessWidget {
  const UnlockVideoRow({super.key});

  @override
  Widget build(BuildContext context) {
    return _surface(
      color: AppBrand.blueTint,
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Offline video on how to unlock all',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppBrand.blue,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spaceSm),
          Icon(
            Icons.chevron_right,
            size: AppIconSize.iconSizeMd,
            color: AppBrand.blue,
          ),
        ],
      ),
    );
  }
}

Widget _surface({
  required Widget child,
  Color color = AppColors.colorSurface,
  EdgeInsets padding = const EdgeInsets.symmetric(
    horizontal: AppSpacing.spaceMd,
    vertical: AppSpacing.spaceMd,
  ),
}) {
  return Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.radiusCard),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}
