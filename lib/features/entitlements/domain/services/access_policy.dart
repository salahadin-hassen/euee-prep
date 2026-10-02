/// Which content a student can open while a stream is still unpurchased.
///
/// Entitlement itself is all-or-nothing per stream (Decision 003/009):
/// buying a stream opens every subject in it at once. The approved
/// reference screens additionally show a free-sample allowance for the
/// locked state — the first [freeSampleLimit] subjects of a stream, and
/// the newest [freeSampleLimit] papers of a subject, stay reachable
/// without an entitlement. That is the "free-sample content stays
/// reachable regardless of entitlement state" rule from
/// `docs/project-requirements.md`, given a concrete shape.
///
/// This lives in the entitlements service layer (Decision 026) so the
/// Subjects list, the Home preview and the Past Papers screen all derive
/// "can this row be opened?" from one place instead of each inventing an
/// allowance.
class AccessPolicy {
  const AccessPolicy._();

  /// How many items at the head of a list are open while the stream is
  /// locked. Sampled from the approved Subjects and Past Papers
  /// reference screens: three subjects open / three newest papers open,
  /// everything after the [lockedDivider] is locked.
  static const int freeSampleLimit = 3;

  /// Whether the item at [index] (0-based, in display order) can be
  /// opened. [isEntitled] is the stream-level entitlement.
  static bool isOpen({required int index, required bool isEntitled}) =>
      isEntitled || index < freeSampleLimit;
}
