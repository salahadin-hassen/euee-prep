import 'package:flutter/material.dart';

import '../../../../core/design/subject_palette.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/progress_bar.dart';
import '../../../../core/design/widgets/subject_icon_tile.dart';
import '../../../../core/providers.dart';
import '../../../subjects/domain/models/subject.dart';

/// "Your subjects" preview card — the first few subjects of the Preferred
/// Stream with their real answered/total counts, inside a single white
/// surface.
class SubjectPreviewCard extends StatelessWidget {
  const SubjectPreviewCard({
    super.key,
    required this.subjects,
    required this.stats,
    required this.onSubjectTap,
  });

  final List<Subject> subjects;
  final Map<int, SubjectStats> stats;

  /// [index] is the subject's position in the full stream list, so the
  /// caller can resolve free-sample access through `AccessPolicy`.
  final void Function(Subject subject, int index) onSubjectTap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < subjects.length; i++) {
      if (i > 0) {
        children.add(const Divider(height: 1, color: AppColors.colorBorder));
      }
      final subject = subjects[i];
      children.add(
        _SubjectPreviewRow(
          subject: subject,
          stats: stats[subject.id] ?? const SubjectStats(paperCount: 0, questionCount: 0, answeredCount: 0),
          onTap: () => onSubjectTap(subject, i),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SubjectPreviewRow extends StatelessWidget {
  const _SubjectPreviewRow({
    required this.subject,
    required this.stats,
    required this.onTap,
  });

  final Subject subject;
  final SubjectStats stats;
  final VoidCallback onTap;

  String get _percentLabel {
    final progress = stats.progress;
    if (progress == null) return '\u{2014}';
    return '${(progress * 100).round()}%';
  }

  String get _caption {
    if (stats.questionCount > 0) {
      return '${stats.answeredCount} of ${stats.questionCount} questions';
    }
    if (stats.paperCount > 0) {
      return '${stats.paperCount} papers ready to download';
    }
    return 'No papers yet';
  }

  @override
  Widget build(BuildContext context) {
    final accent = SubjectPalette.accentOf(subject.slug);
    final progress = stats.progress ?? 0;

    return Semantics(
      button: true,
      label: '${subject.title}. $_caption. Double tap to open.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.spaceSm,
            AppSpacing.spaceMd,
            AppSpacing.spaceSm,
            AppSpacing.spaceMd,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 46,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceMd),
              SubjectIconTile(slug: subject.slug),
              const SizedBox(width: AppSpacing.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.colorTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spaceSm),
                        Text(
                          _percentLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppBrand.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spaceSm),
                    ProgressBar(
                      progress: progress,
                      fillColor: accent,
                    ),
                    const SizedBox(height: AppSpacing.spaceSm),
                    Text(
                      _caption,
                      style: AppTypography.typeCaption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSm),
              const Icon(
                Icons.chevron_right,
                size: AppIconSize.iconSizeMd,
                color: AppColors.colorTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
