import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// Cream top bar of the Home screen: menu affordance on the left, the
/// Preferred Stream name centred.
///
/// The menu button opens Settings — the same destination the reference
/// design's drawer would reach — because no drawer exists in the app and
/// Preferred Stream may only be changed there (Decision 014).
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.streamName,
    required this.onMenuTap,
  });

  final String streamName;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceXs,
        AppSpacing.spaceXs,
        AppSpacing.spaceXs,
        0,
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu, color: AppColors.colorTextPrimary),
              onPressed: onMenuTap,
            ),
            Expanded(
              child: Center(
                child: Text(
                  streamName,
                  style: AppTypography.typeBody.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppBrand.navy,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
