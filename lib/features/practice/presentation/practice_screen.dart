import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import '../../subjects/presentation/flashcards_screen.dart';
import 'exam_navigator_sheet.dart';
import 'exam_review_screen.dart';
import 'mock/mock_bookmark_store.dart';
import 'mock/mock_practice_questions.dart';
import 'models/practice_models.dart';
import 'session_summary_screen.dart';
import 'widgets/practice_app_bar.dart';
import 'widgets/practice_timer.dart';
import 'widgets/question_card.dart';

/// One practice engine, three interaction experiences (Learn/Practice/
/// Exam) — see the Practice/Exam UX spec (v3) for full mode reasoning.
///
/// Presentation-layer only. Question data currently comes from
/// [MockPracticeQuestions]. Also serves as the Retry Wrong destination
/// (same screen, filtered [questions] list, same [mode]).
///
/// TODO(integration): each submitted/selected answer should trigger a
/// real Attempt-repository write via the Service layer (Decision 016 —
/// append-only). Currently only tracked in local presentation state for
/// the mock session summary calculation.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.mode,
    required this.questions,
    required this.chapterId,
    required this.chapterTitle,
  });

  final PracticeMode mode;
  final List<QuestionUiModel> questions;
  final String chapterId;
  final String chapterTitle;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final List<QuestionAttemptState> _states =
      List.generate(widget.questions.length, (_) => QuestionAttemptState());

  int _currentIndex = 0;

  // Practice Mode: timer starts hidden, student opts in.
  bool _practiceTimerOn = false;
  // Exam Mode: timer always active, but visually collapsible.
  bool _examTimerCollapsed = false;

  Timer? _countdownTicker;
  late int _remainingSeconds =
      ExamPacingConfig.sessionTimeSeconds(widget.questions.length);
  final Stopwatch _sessionStopwatch = Stopwatch()..start();

  bool get _timerShouldRun =>
      widget.mode == PracticeMode.exam ||
      (widget.mode == PracticeMode.practice && _practiceTimerOn);

  @override
  void initState() {
    super.initState();
    if (widget.mode == PracticeMode.exam) _startCountdown();
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTicker?.cancel();
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _countdownTicker?.cancel();
        if (widget.mode == PracticeMode.exam) _handleTimeUp();
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  void _handleTimeUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Time's up — submitting your exam.")),
    );
    Future<void>.delayed(const Duration(seconds: 1), _submitExam);
  }

  // --- Learn/Practice: select then explicit submit ---

  void _handleSelectOption(int index) {
    final mode = widget.mode;
    setState(() {
      _states[_currentIndex].selectedIndex = index;
      // Exam Mode has no separate submit step — selecting IS answering
      // (matches real exam behavior: freely revisable until the whole
      // exam is submitted).
      if (mode == PracticeMode.exam) {
        _states[_currentIndex].isSubmitted = true;
      }
    });
  }

  void _handleSubmitAnswer() {
    setState(() => _states[_currentIndex].isSubmitted = true);
  }

  void _handleContinue() {
    if (_currentIndex >= widget.questions.length - 1) {
      _goToSummary();
      return;
    }
    setState(() => _currentIndex += 1);
  }

  // --- Exam: free navigation ---

  void _goToIndex(int index) {
    setState(() => _currentIndex = index.clamp(0, widget.questions.length - 1));
  }

  Future<void> _openNavigator() async {
    final selected = await showExamNavigator(
      context: context,
      states: _states,
      currentIndex: _currentIndex,
    );
    if (selected != null) _goToIndex(selected);
  }

  Future<void> _openReview() async {
    final action = await Navigator.of(context).push<_ReviewAction>(
      MaterialPageRoute(
        builder: (context) => ExamReviewScreen(
          states: _states,
          remainingSeconds: _remainingSeconds,
          onReviewQuestions: () =>
              Navigator.of(context).pop(_ReviewAction.reviewQuestions),
          onSubmitExam: () => Navigator.of(context).pop(_ReviewAction.submit),
        ),
      ),
    );
    if (action == _ReviewAction.submit) _submitExam();
    // reviewQuestions just returns to the current question — the
    // student uses the AppBar navigator to jump around from there.
  }

  void _submitExam() {
    _countdownTicker?.cancel();
    _goToSummary();
  }

  // --- Bookmark (Learn/Practice) & Mark for Review (Exam) ---

  void _toggleBookmark() {
    setState(() {
      MockBookmarkStore.toggle(widget.questions[_currentIndex].questionId);
    });
  }

  void _toggleFlag() {
    setState(() {
      _states[_currentIndex].isFlagged = !_states[_currentIndex].isFlagged;
    });
  }

  // --- Exit / completion ---

  Future<bool> _handleBackPressed() async {
    final hasAnyProgress = _states.any((s) => s.isAnswered);
    if (!hasAnyProgress) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Practice?'),
        content: const Text(
          'Your completed answers have already been saved. '
          'You can continue later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  void _goToSummary() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SessionSummaryScreen(
          mode: widget.mode,
          questions: widget.questions,
          states: _states,
          totalTimeSeconds: _sessionStopwatch.elapsed.inSeconds,
          timeRemainingSeconds:
              widget.mode == PracticeMode.exam ? _remainingSeconds : null,
          onRetryWrong: (wrongQuestions) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PracticeScreen(
                  mode: widget.mode,
                  questions: wrongQuestions,
                  chapterId: widget.chapterId,
                  chapterTitle: widget.chapterTitle,
                ),
              ),
            );
          },
          onReviewResources: () => Navigator.of(context).pop(),
          onBackToChapter: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openResourceScreen(String label) {
    if (label == 'Flashcards') {
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
    // TODO(integration): Notes and Mind Map screens don't exist yet.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label screen coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _handleBackPressed()) {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.colorBackground,
        appBar: _buildAppBar(),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  PracticeAppBar _buildAppBar() {
    Widget? timerWidget;
    if (widget.mode == PracticeMode.exam) {
      timerWidget = PracticeTimer(
        remainingSeconds: _remainingSeconds,
        totalSeconds:
            ExamPacingConfig.sessionTimeSeconds(widget.questions.length),
        isCollapsed: _examTimerCollapsed,
        onToggleCollapsed: () =>
            setState(() => _examTimerCollapsed = !_examTimerCollapsed),
      );
    } else if (widget.mode == PracticeMode.practice) {
      timerWidget = _practiceTimerOn
          ? PracticeTimer(
              remainingSeconds: _remainingSeconds,
              totalSeconds:
                  ExamPacingConfig.sessionTimeSeconds(widget.questions.length),
              isCollapsed: false,
              onToggleCollapsed: () {
                setState(() => _practiceTimerOn = false);
                _countdownTicker?.cancel();
              },
            )
          : IconButton(
              icon: const Icon(Icons.timer_outlined,
                  color: AppColors.colorTextSecondary),
              tooltip: 'Show timer',
              onPressed: () {
                setState(() => _practiceTimerOn = true);
                _startCountdown();
              },
            );
    }

    return PracticeAppBar(
      mode: widget.mode,
      currentIndex: _currentIndex,
      totalQuestions: widget.questions.length,
      answeredCount: _states.where((s) => s.isAnswered).length,
      flaggedCount: _states.where((s) => s.isFlagged).length,
      onBack: () async {
        if (await _handleBackPressed() && mounted) Navigator.of(context).pop();
      },
      timerWidget: timerWidget,
      isBookmarked: MockBookmarkStore.isBookmarked(
          widget.questions[_currentIndex].questionId),
      onToggleBookmark: _toggleBookmark,
      isCurrentFlagged: _states[_currentIndex].isFlagged,
      onToggleFlag: _toggleFlag,
      onOpenNavigator: _openNavigator,
      onOpenReview: _openReview,
    );
  }

  Widget _buildBody() {
    final question = widget.questions[_currentIndex];
    final state = _states[_currentIndex];
    final showFeedback = widget.mode != PracticeMode.exam && state.isSubmitted;

    return Column(
      children: [
        Expanded(
          child: QuestionCard(
            question: question,
            attemptState: state,
            showFeedback: showFeedback,
            onSelectOption: _handleSelectOption,
            notesAvailable: true,
            flashcardsAvailable: true,
            mindMapAvailable: true,
            onViewNotes: () => _openResourceScreen('Notes'),
            onViewFlashcards: () => _openResourceScreen('Flashcards'),
            onViewMindMap: () => _openResourceScreen('Mind Map'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMd),
          child: widget.mode == PracticeMode.exam
              ? _buildExamNavRow()
              : _buildLinearActionButton(state),
        ),
      ],
    );
  }

  Widget _buildLinearActionButton(QuestionAttemptState state) {
    return AppButton(
      label: state.isSubmitted ? 'Continue →' : 'Submit Answer',
      isFullWidth: true,
      onPressed: state.isSubmitted
          ? _handleContinue
          : (state.isAnswered ? _handleSubmitAnswer : null),
    );
  }

  Widget _buildExamNavRow() {
    final isLast = _currentIndex == widget.questions.length - 1;
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Previous',
            variant: AppButtonVariant.secondary,
            isFullWidth: true,
            onPressed:
                _currentIndex > 0 ? () => _goToIndex(_currentIndex - 1) : null,
          ),
        ),
        const SizedBox(width: AppSpacing.spaceMd),
        Expanded(
          child: AppButton(
            label: isLast ? 'Finish' : 'Next',
            isFullWidth: true,
            onPressed:
                isLast ? _openReview : () => _goToIndex(_currentIndex + 1),
          ),
        ),
      ],
    );
  }
}

enum _ReviewAction { reviewQuestions, submit }
