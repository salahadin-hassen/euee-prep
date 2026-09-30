import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';
import '../../content/domain/models/exam.dart';
import '../../practice/presentation/models/practice_models.dart';
import '../../practice/presentation/practice_screen.dart';

/// Decodes the `choices_json` column into the option list shown in practice.
///
/// The importer writes this column with `jsonEncode`, so it must be read back
/// with the matching JSON parser: choices routinely contain commas, quotes and
/// brackets (e.g. `"Option A, with a comma"`), which the previous
/// `replaceAll`/`split(',')` parsing mangled into extra options.
///
/// Throws [FormatException] when the stored value is not a JSON array of
/// strings — malformed content must fail loudly rather than render as
/// silently corrupted options.
List<String> decodeChoicesJson(String choicesJson) {
  final Object? decoded;
  try {
    decoded = jsonDecode(choicesJson);
  } on FormatException catch (e) {
    throw FormatException('choices_json is not valid JSON: ${e.message}');
  }
  if (decoded is! List) {
    throw const FormatException('choices_json must be a JSON array of strings');
  }
  return decoded.map((element) {
    if (element is! String) {
      throw const FormatException(
        'choices_json must be a JSON array of strings',
      );
    }
    return element;
  }).toList();
}


/// Subject Detail screen — shows past papers for one subject.
///
/// Data is loaded from the real database via [examsBySubjectProvider].
class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  final int subjectId;
  final String subjectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsBySubjectProvider(subjectId));

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: Text(subjectName, style: AppTypography.typeHeading3),
      ),
      body: SafeArea(
        child: examsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (exams) {
            if (exams.isEmpty) {
              return const _NoPapers();
            }
            return _PaperList(exams: exams, subjectName: subjectName);
          },
        ),
      ),
    );
  }
}

class _PaperList extends StatelessWidget {
  const _PaperList({required this.exams, required this.subjectName});

  final List<Exam> exams;
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      children: [
        Text(
          'Past papers',
          style: AppTypography.typeCaption.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.spaceSm),
        for (var i = 0; i < exams.length; i++) ...[
          _PaperCard(
            exam: exams[i],
            subjectName: subjectName,
            onTap: () => _showStartSheet(context, exams[i], subjectName),
          ),
          if (i < exams.length - 1)
            const SizedBox(height: AppSpacing.spaceMd),
        ],
      ],
    );
  }

  void _showStartSheet(
    BuildContext context,
    Exam exam,
    String subjectName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.colorBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
      ),
      builder: (context) => _PaperStartSheet(
        exam: exam,
        subjectName: subjectName,
        onStart: () {
          Navigator.of(context).pop();
          _openPractice(context, exam, subjectName);
        },
      ),
    );
  }

  void _openPractice(
    BuildContext context,
    Exam exam,
    String subjectName,
  ) async {
    final questionRepo =
        ProviderScope.containerOf(context).read(questionRepositoryProvider);
    final questionIds = exam.questionIds;
    if (questionIds.isEmpty) return;

    final questions = await questionRepo.getByIds(questionIds);
    if (!context.mounted) return;

    final idToIndex = <int, int>{};
    for (var i = 0; i < questionIds.length; i++) {
      idToIndex[questionIds[i]] = i;
    }
    final sorted = List.of(questions)
      ..sort((a, b) =>
          (idToIndex[a.id] ?? 0).compareTo(idToIndex[b.id] ?? 0));

    final uiModels = sorted.map((q) {
      return QuestionUiModel(
        dbQuestionId: q.id,
        questionId: q.packLocalId,
        topicIds: const [],
        prompt: q.prompt,
        options: decodeChoicesJson(q.choicesJson),
        correctIndex: q.correctChoiceIndex,
        explanation: q.explanation ?? '',
        textbookReference: q.textbookReference,
      );
    }).toList();

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PracticeScreen(
          mode: PracticeMode.practice,
          questions: uiModels,
          chapterId: exam.packLocalId,
          chapterTitle: '$subjectName ${exam.examYearEc}',
          examId: exam.id,
          subjectId: exam.subjectId,
        ),
      ),
    );
  }
}

/// Minimal bottom sheet shown before starting practice.
class _PaperStartSheet extends StatelessWidget {
  const _PaperStartSheet({
    required this.exam,
    required this.subjectName,
    required this.onStart,
  });

  final Exam exam;
  final String subjectName;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final year = exam.examYearEc;
    final questionCount = exam.questionIds.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.colorBorder,
                  borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            Text('$subjectName $year', style: AppTypography.typeHeading2),
            const SizedBox(height: AppSpacing.spaceXs),
            Text(
              '$questionCount questions',
              style: AppTypography.typeBody
                  .copyWith(color: AppColors.colorTextSecondary),
            ),
            const SizedBox(height: AppSpacing.spaceLg),
            AppButton(
              label: 'Start Practice',
              isFullWidth: true,
              onPressed: onStart,
            ),
            const SizedBox(height: AppSpacing.spaceSm),
          ],
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({
    required this.exam,
    required this.subjectName,
    required this.onTap,
  });

  final Exam exam;
  final String subjectName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final questionCount = exam.questionIds.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.colorSurface,
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
          border: Border.all(color: AppColors.colorBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.colorPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              ),
              child: Center(
                child: Text(
                  '${exam.examYearEc}',
                  style: AppTypography.typeHeading3.copyWith(
                    color: AppColors.colorPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$subjectName ${exam.examYearEc}',
                    style: AppTypography.typeBody
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.spaceXs),
                  Text(
                    '$questionCount questions',
                    style: AppTypography.typeCaption,
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'Open',
              variant: AppButtonVariant.secondary,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoPapers extends StatelessWidget {
  const _NoPapers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: AppIconSize.iconSizeXl,
              color: AppColors.colorTextSecondary,
            ),
            SizedBox(height: AppSpacing.spaceMd),
            Text(
              'No papers available',
              style: AppTypography.typeHeading3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spaceSm),
            Text(
              'Import a content pack for this subject.',
              style: AppTypography.typeCaption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
