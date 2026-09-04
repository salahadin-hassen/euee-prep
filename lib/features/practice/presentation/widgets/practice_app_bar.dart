import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/progress_bar.dart';
import '../models/practice_models.dart';

/// Combined AppBar + thin progress row for PracticeScreen.
///
/// Trailing icon set is mode-dependent per the UX spec:
/// - Learn: bookmark only, no timer, no navigator.
/// - Practice: bookmark + optional timer (shown only when toggled on
///   by the caller — this widget doesn't own that toggle state).
/// - Exam: mark-for-review + navigator + always-on timer (collapsible).
///
/// The progress row shows answered count in Practice/Exam (meaningful
/// once answers can be revisited/jumped-to) and flagged count in Exam
/// only — omitted in Learn Mode per the spec's "redundant with
/// position" reasoning.
class PracticeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PracticeAppBar({
    super.key,
    required this.mode,
    required this.currentIndex,
    required this.totalQuestions,
    required this.answeredCount,
    required this.flaggedCount,
    required this.onBack,
    this.timerWidget,
    this.isBookmarked = false,
    this.onToggleBookmark,
    this.isCurrentFlagged = false,
    this.onToggleFlag,
    this.onOpenNavigator,
    this.onOpenReview,
  });

  final PracticeMode mode;
  final int currentIndex; // 0-based
  final int totalQuestions;
  final int answeredCount;
  final int flaggedCount;
  final VoidCallback onBack;

  /// Built by the parent (PracticeTimer instance) — null when the
  /// timer should not appear at all (Learn, or Practice with the
  /// toggle off).
  final Widget? timerWidget;

  final bool isBookmarked;
  final VoidCallback? onToggleBookmark;

  final bool isCurrentFlagged;
  final VoidCallback? onToggleFlag;

  final VoidCallback? onOpenNavigator;
  final VoidCallback? onOpenReview;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 32);

  @override
  Widget build(BuildContext context) {
    final positionLabel = '${currentIndex + 1}/$totalQuestions';

    return PreferredSize(
      preferredSize: preferredSize,
      child: Column(
        children: [
          AppBar(
            backgroundColor: AppColors.colorBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: onBack,
            ),
            title: Text(positionLabel, style: AppTypography.typeHeading3),
            actions: [
              if (mode == PracticeMode.learn || mode == PracticeMode.practice)
                IconButton(
                  icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
                  tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
                  onPressed: onToggleBookmark,
                ),
              if (mode == PracticeMode.exam) ...[
                IconButton(
                  icon: Icon(isCurrentFlagged ? Icons.flag : Icons.outlined_flag),
                  tooltip: isCurrentFlagged ? 'Remove review flag' : 'Mark for review',
                  onPressed: onToggleFlag,
                ),
                IconButton(
                  icon: const Icon(Icons.grid_view_outlined),
                  tooltip: 'Question navigator',
                  onPressed: onOpenNavigator,
                ),
                IconButton(
                  icon: const Icon(Icons.playlist_add_check),
                  tooltip: 'Review',
                  onPressed: onOpenReview,
                ),
              ],
              if (timerWidget != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.spaceSm),
                  child: timerWidget!,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
            child: Row(
              children: [
                Expanded(
                  child: ProgressBar(
                    progress: (currentIndex + 1) / totalQuestions,
                  ),
                ),
                if (mode != PracticeMode.learn) ...[
                  const SizedBox(width: AppSpacing.spaceSm),
                  const Icon(Icons.check_circle_outline,
                      size: AppIconSize.iconSizeSm, color: AppColors.colorTextSecondary),
                  const SizedBox(width: 2),
                  Text('$answeredCount', style: AppTypography.typeCaption),
                ],
                if (mode == PracticeMode.exam) ...[
                  const SizedBox(width: AppSpacing.spaceSm),
                  const Icon(Icons.flag_outlined,
                      size: AppIconSize.iconSizeSm, color: AppColors.colorTextSecondary),
                  const SizedBox(width: 2),
                  Text('$flaggedCount', style: AppTypography.typeCaption),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spaceXs),
        ],
      ),
    );
  }
}
