import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/design/tokens.dart';

/// The single flip-card widget: shows [front] until tapped, then
/// flips to reveal [back]. A 3D-style rotation, not a cross-fade, so
/// the "flip" gesture reads clearly rather than just swapping text.
///
/// Purpose-built for the Flashcards screen's specific interaction — not
/// generalized into a shared primitive, since no other screen currently
/// needs a flip-reveal pattern.
class FlashcardView extends StatefulWidget {
  const FlashcardView({
    super.key,
    required this.front,
    required this.back,
    required this.isFlipped,
    required this.onTap,
  });

  final String front;
  final String back;

  /// Flip state is owned by the parent (FlashcardsScreen) so it can be
  /// reset to "front" whenever the deck advances to a new card.
  final bool isFlipped;
  final VoidCallback onTap;

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDuration.durationMedium,
  );

  @override
  void didUpdateWidget(covariant FlashcardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.isFlipped
          ? 'Flashcard back, showing answer: ${widget.back}'
          : 'Flashcard front, ${widget.front}. Tap to reveal answer.',
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _controller.value * pi;
            final showBack = _controller.value > 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _CardFace(
                        text: widget.back,
                        isFront: false,
                      ),
                    )
                  : _CardFace(text: widget.front, isFront: true),
            );
          },
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.text, required this.isFront});

  final String text;
  final bool isFront;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: AppColors.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                text,
                style: AppTypography.typeHeading2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (isFront) ...[
            const SizedBox(height: AppSpacing.spaceMd),
            Text('tap to flip', style: AppTypography.typeCaption),
          ],
        ],
      ),
    );
  }
}
