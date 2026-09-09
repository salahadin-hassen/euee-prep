import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'mock/mock_chapters.dart';
import 'models/chapter_ui_model.dart';
import 'study_resources_screen.dart';
import 'widgets/grade_section.dart';
import 'widgets/subject_detail_header.dart';

/// Subject Detail screen (Decision 014): grade-grouped chapter list for
/// one subject. Reached by tapping an entitled subject on Subject List.
///
/// Presentation-layer only. Data currently comes from [MockChapters].
///
/// TODO(integration): Replace mock data with a real provider reading
/// Chapter scoped to (subjectId, each Grade) via the Chapter repository
/// (Decision 010), and per-chapter/overall completion from a
/// Service-layer rollup over Attempt history (Decision 016 — never a
/// stored value).
///
/// TODO(integration): "which grade section is expanded by default"
/// currently always defaults to Grade 12 (see design review — a
/// placeholder pending real "most recently studied grade" data, which
/// doesn't exist yet in mock form).
class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.overallProgress,
  });

  final String subjectId;
  final String subjectName;
  final double overallProgress;

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  bool _isLoading = true;
  List<GradeSectionUiModel> _sections = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _sections = MockChapters.forSubject(widget.subjectId);
      _isLoading = false;
    });
  }

  void _handleChapterTap(ChapterUiModel chapter, int grade) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudyResourcesScreen(
          chapterId: chapter.chapterId,
          chapterTitle: chapter.title,
          grade: grade,
          subjectName: widget.subjectName,
        ),
      ),
    );
  }

  int get _totalChapterCount =>
      _sections.fold(0, (sum, s) => sum + s.chapters.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: Text(widget.subjectName, style: AppTypography.typeHeading3),
      ),
      body: SafeArea(
        child: _isLoading ? const _SubjectDetailSkeleton() : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      children: [
        SubjectDetailHeader(
          subjectName: widget.subjectName,
          chapterCount: _totalChapterCount,
          overallProgress: widget.overallProgress,
        ),
        for (final section in _sections)
          GradeSection(
            section: section,
            // Placeholder default per the design review: Grade 12
            // expanded, others collapsed, until real "most recently
            // studied" data exists.
            initiallyExpanded: section.grade == 12,
            onChapterTap: (chapter) =>
                _handleChapterTap(chapter, section.grade),
          ),
        const SizedBox(height: AppSpacing.spaceLg),
      ],
    );
  }
}

/// Skeleton loading state — header skeleton + 4 collapsed-looking
/// placeholder bars, consistent with the pattern used on the previous
/// two screens.
class _SubjectDetailSkeleton extends StatelessWidget {
  const _SubjectDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(width: 140, height: 24),
          const SizedBox(height: AppSpacing.spaceSm),
          _bar(width: 180, height: 12),
          const SizedBox(height: AppSpacing.spaceMd),
          _bar(width: double.infinity, height: 6),
          const SizedBox(height: AppSpacing.spaceLg),
          for (var i = 0; i < 4; i++) ...[
            _bar(width: double.infinity, height: 48),
            const SizedBox(height: AppSpacing.spaceSm),
          ],
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
