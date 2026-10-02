import 'package:flutter/material.dart';

import 'tokens.dart';

/// Per-subject accent colors used by the Home subject preview rows and the
/// Subjects list icon tiles (Home/Subjects reference screens).
///
/// Accent hues are sampled from the reference screens for the three
/// Natural Science subjects shown there; the remaining subjects fall back
/// to the brand blue so every subject still gets a distinct-looking tile
/// without inventing additional brand hues.
class SubjectPalette {
  SubjectPalette._();

  static const Color _biology = Color(0xFF2FA85A);
  static const Color _chemistry = Color(0xFF2F6FD0);
  static const Color _physics = Color(0xFFE8862A);

  /// Strong accent for a subject — used for the left accent bar.
  static Color accentOf(String slug) {
    switch (slug) {
      case 'biology':
        return _biology;
      case 'chemistry':
        return _chemistry;
      case 'physics':
        return _physics;
      default:
        return AppBrand.blue;
    }
  }

  /// Light tint of [accentOf] — used behind subject icon glyphs.
  static Color tintOf(String slug) =>
      accentOf(slug).withValues(alpha: 0.14);
}

/// Decorative emoji glyph for a subject slug.
///
/// Emoji stand-in until real iconography is designed — flagged, not a
/// final asset decision. Same mapping the Subject List has always used.
String subjectIconForSlug(String slug) {
  switch (slug) {
    case 'physics':
      return '\u{1F9EA}';
    case 'mathematics':
      return '\u{1F4D0}';
    case 'chemistry':
      return '\u{2697}\u{FE0F}';
    case 'biology':
      return '\u{1F9EC}';
    case 'english':
      return '\u{1F4D6}';
    case 'sat_aptitude':
      return '\u{1F9E9}';
    case 'geography':
      return '\u{1F30D}';
    case 'history':
      return '\u{1F3DB}\u{FE0F}';
    case 'economics':
      return '\u{1F4B0}';
    default:
      return '\u{1F4DA}';
  }
}
