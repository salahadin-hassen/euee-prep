import 'package:flutter/material.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/confirmation_screen.dart';
import 'mock/mock_flashcards.dart';
import 'models/flashcard_ui_model.dart';
import 'widgets/flashcard_nav_controls.dart';
import 'widgets/flashcard_view.dart';

/// Flashcards screen: linear, session-based deck for one chapter.
///
/// No spaced-repetition scheduling, no difficulty self-rating — flip,
/// then Next, per the design review's deliberate scope limit (this
/// would be real rework to add later, not a small extension).
///
/// Presentation-layer only. Data currently comes from [MockFlashcards].
///
/// TODO(integration): Replace mock data with a real provider supplying
/// FlashcardUiModel instances from Resource records scoped to this
/// chapter's Topics (Decision 011).
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
  });

  final String chapterId;
  final String chapterTitle;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  bool _isLoading = true;
  List<FlashcardUiModel> _cards = const [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isDeckComplete = false;

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
      _cards = MockFlashcards.forChapter(widget.chapterId);
      _isLoading = false;
    });
  }

  void _handleFlip() => setState(() => _isFlipped = !_isFlipped);

  void _goNext() {
    if (_currentIndex >= _cards.length - 1) {
      setState(() => _isDeckComplete = true);
      return;
    }
    setState(() {
      _currentIndex += 1;
      _isFlipped = false;
    });
  }

  void _goPrevious() {
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex -= 1;
      _isFlipped = false;
    });
  }

  void _restartDeck({required bool reshuffle}) {
    setState(() {
      if (reshuffle) _cards = List.of(_cards)..shuffle();
      _currentIndex = 0;
      _isFlipped = false;
      _isDeckComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _isDeckComplete) {
      return ConfirmationScreen(
        headline: "You've reviewed all ${_cards.length} flashcards",
        actions: [
          ConfirmationAction(
            label: 'Study Again',
            onPressed: () => _restartDeck(reshuffle: true),
          ),
          ConfirmationAction(
            label: 'Back to Chapter',
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: AppColors.colorBackground,
        elevation: 0,
        title: Text('Flashcards', style: AppTypography.typeHeading3),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.spaceMd),
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${_cards.length}',
                  style: AppTypography.typeCaption,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading ? const _FlashcardsSkeleton() : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final card = _cards[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity < -200) {
                    _goNext();
                  } else if (velocity > 200) {
                    _goPrevious();
                  }
                },
                child: FlashcardView(
                  front: card.front,
                  back: card.back,
                  isFlipped: _isFlipped,
                  onTap: _handleFlip,
                ),
              ),
            ),
          ),
          FlashcardNavControls(
            canGoPrevious: _currentIndex > 0,
            onPrevious: _goPrevious,
            onNext: _goNext,
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading state — a single placeholder card shape, simpler
/// than other screens' multi-item skeletons since there's only one
/// focal element here.
class _FlashcardsSkeleton extends StatelessWidget {
  const _FlashcardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spaceMd),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.colorDisabled.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
      ),
    );
  }
}
