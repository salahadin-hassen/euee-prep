import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// "Studying: [Stream]" orientation label under the top bar.
///
/// Purely presentational and non-interactive — Preferred Stream is
/// only changed in Settings (Decision 014), never from this screen, so
/// this label exists only to orient the student, not to invite a tap.
class SubjectListHeader extends StatelessWidget {
  const SubjectListHeader({super.key, required this.streamName});

  final String streamName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceMd,
        0,
        AppSpacing.spaceMd,
        AppSpacing.spaceSm,
      ),
      child: Text(
        'Studying: $streamName',
        style: AppTypography.typeCaption,
      ),
    );
  }
}
