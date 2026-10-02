import 'package:flutter/material.dart';

import '../subject_palette.dart';
import '../tokens.dart';

/// 40dp tinted square holding a subject's decorative glyph.
///
/// Shared by the Home subject preview rows and the Subjects list cards so
/// both screens draw the same tile.
class SubjectIconTile extends StatelessWidget {
  const SubjectIconTile({
    super.key,
    required this.slug,
    this.size = 40,
    this.locked = false,
  });

  final String slug;
  final double size;

  /// Renders the tile in the muted locked palette used by the Subjects
  /// list for subjects the student cannot open yet.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: locked
            ? AppColors.colorDisabled.withValues(alpha: 0.28)
            : SubjectPalette.tintOf(slug),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      alignment: Alignment.center,
      child: Text(
        subjectIconForSlug(slug),
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}
