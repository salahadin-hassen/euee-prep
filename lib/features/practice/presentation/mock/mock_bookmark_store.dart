// TEMPORARY MOCK STORE.
//
// Bookmarks (Learn/Practice modes) persist across sessions conceptually,
// unlike Mark-for-Review (Exam Mode only, session-scoped, lives in
// QuestionAttemptState). This in-memory Set stands in for that
// persistence only for the lifetime of the running app — it is lost on
// app restart.
//
// TODO(integration): replace with a real local-only Local Data Source
// (Decision 026's layering) — e.g. a Drift table or key-value store,
// keyed by questionId, with no backend involvement (Decision 017:
// bookmarks are local-only, like Preferred Stream).

class MockBookmarkStore {
  MockBookmarkStore._();

  static final Set<String> _bookmarkedQuestionIds = {};

  static bool isBookmarked(String questionId) =>
      _bookmarkedQuestionIds.contains(questionId);

  static void toggle(String questionId) {
    if (_bookmarkedQuestionIds.contains(questionId)) {
      _bookmarkedQuestionIds.remove(questionId);
    } else {
      _bookmarkedQuestionIds.add(questionId);
    }
  }
}
