import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';
import '../models/chapter_ui_model.dart';
import 'chapter_row.dart';

/// Collapsible "Grade N (M chapters)" section containing [ChapterRow]s.
///
/// Custom-built rather than Flutter's built-in ExpansionTile — its
/// default styling/ripple doesn't follow this design system's token
/// contract, per the design review's explicit note. Chapter rows are
/// only built while expanded (not just visually hidden), matching the
/// performance note in the design review — collapsed sections stay
/// cheap even on subjects with many chapters.
class GradeSection extends StatefulWidget {
  const GradeSection({
    super.key,
    required this.section,
    required this.initiallyExpanded,
    required this.onChapterTap,
  });

  final GradeSectionUiModel section;
  final bool initiallyExpanded;
  final ValueChanged<ChapterUiModel> onChapterTap;

  @override
  State<GradeSection> createState() => _GradeSectionState();
}

class _GradeSectionState extends State<GradeSection> {
  late bool _isExpanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    if (section.chapters.isEmpty) {
      // Defensive: an empty grade section simply doesn't render, rather
      // than showing a dead-end disclosure with nothing inside it.
      return const SizedBox.shrink();
    }

    final chapterCountLabel = '${section.chapters.length} chapters';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Grade ${section.grade}, $chapterCountLabel, '
              '${_isExpanded ? 'expanded' : 'collapsed. Double tap to expand.'}',
          button: true,
          excludeSemantics: true,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spaceMd,
                vertical: AppSpacing.spaceMd,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Grade ${section.grade}',
                      style: AppTypography.typeHeading3,
                    ),
                  ),
                  Text(
                    '($chapterCountLabel)',
                    style: AppTypography.typeCaption,
                  ),
                  const SizedBox(width: AppSpacing.spaceSm),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: AppDuration.durationFast,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.colorTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppDuration.durationMedium,
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Column(
                  children: [
                    for (final chapter in section.chapters)
                      ChapterRow(
                        chapter: chapter,
                        onTap: () => widget.onChapterTap(chapter),
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
