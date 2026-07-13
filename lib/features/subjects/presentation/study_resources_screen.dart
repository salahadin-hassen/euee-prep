import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'flashcards_screen.dart';
import 'mock/mock_study_resources.dart';
import 'models/study_resource_ui_model.dart';
import 'widgets/chapter_context_header.dart';
import 'widgets/practice_card.dart';
import 'widgets/study_resource_card.dart';

/// Study Resources screen (Decision 014): mode-selection menu for one
/// chapter — Notes, Flashcards, Mind Map, and Practice. Reached by
/// tapping a Chapter on Subject Detail.
///
/// A pure router screen — it holds no content itself, only decides
/// which of the four downstream screens to open.
///
/// Presentation-layer only. Data currently comes from
/// [MockStudyResources].
///
/// TODO(integration): Replace mock data with a real provider
/// aggregating Resource records across all Topics in this chapter
/// (Decision 011), and a Question count via the Chapter→Topic→Question
/// many-to-many join.
class StudyResourcesScreen extends StatefulWidget {
  const StudyResourcesScreen({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
    required this.grade,
    required this.subjectName,
  });

  final String chapterId;
  final String chapterTitle;
  final int grade;
  final String subjectName;

  @override
  State<StudyResourcesScreen> createState() => _StudyResourcesScreenState();
}

class _StudyResourcesScreenState extends State<StudyResourcesScreen> {
  bool _isLoading = true;
  List<StudyResourceUiModel> _resources = const [];
  PracticeUiModel? _practice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _resources = MockStudyResources.resourcesFor(widget.chapterId);
      _practice = MockStudyResources.practiceFor(widget.chapterId);
      _isLoading = false;
    });
  }

  void _handleResourceTap(StudyResourceUiModel resource) {
    if (resource.type == StudyResourceType.flashcards) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FlashcardsScreen(
            chapterId: widget.chapterId,
            chapterTitle: widget.chapterTitle,
          ),
        ),
      );
      return;
    }

    // TODO(integration): navigate to the Notes / Mind Map screen for
    // this chapter. Not yet designed.
    final label = switch (resource.type) {
      StudyResourceType.notes => 'Notes',
      StudyResourceType.mindMap => 'Mind Map',
      StudyResourceType.flashcards => 'Flashcards', // unreachable here
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label screen coming soon')),
    );
  }

  void _handlePracticeTap() {
    // TODO(integration): navigate to the Practice/Exam screen for this
    // chapter's tagged questions (Decision 011). Not yet designed.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Practice screen coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: Text(widget.chapterTitle, style: AppTypography.typeHeading3),
      ),
      body: SafeArea(
        child: _isLoading ? const _StudyResourcesSkeleton() : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      children: [
        ChapterContextHeader(
          chapterTitle: widget.chapterTitle,
          grade: widget.grade,
          subjectName: widget.subjectName,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
          child: Column(
            children: [
              for (final resource in _resources) ...[
                StudyResourceCard(
                  resource: resource,
                  onTap: () => _handleResourceTap(resource),
                ),
                const SizedBox(height: AppSpacing.spaceMd),
              ],
              if (_practice != null)
                PracticeCard(
                  practice: _practice!,
                  onTap: _handlePracticeTap,
                ),
              const SizedBox(height: AppSpacing.spaceLg),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton loading state — header skeleton + 4 placeholder bars,
/// consistent with the pattern used on prior screens.
class _StudyResourcesSkeleton extends StatelessWidget {
  const _StudyResourcesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(width: 160, height: 24),
          const SizedBox(height: AppSpacing.spaceSm),
          _bar(width: 120, height: 12),
          const SizedBox(height: AppSpacing.spaceLg),
          for (var i = 0; i < 4; i++) ...[
            _bar(width: double.infinity, height: 72),
            const SizedBox(height: AppSpacing.spaceMd),
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
