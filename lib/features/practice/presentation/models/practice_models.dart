// Local UI models — presentation layer only.
//
// Not domain models. The real Question/Topic entities (many-to-many,
// Decision 011) and Attempt persistence (append-only, Decision 016) are
// owned by the data/domain/service layers. QuestionAttemptState below
// is transient presentation state for one on-screen session — it is
// NOT the Attempt record itself.
//
// TODO(integration): replace mock construction with a mapper from the
// domain Question model (incl. its many-to-many Topic tags) and wire
// _each submitted answer_ to a real Attempt-repository write via the
// Service layer. Widgets should not need to change.

/// Three interaction experiences over one underlying practice engine.
/// See the Practice/Exam UX spec (v3) for full reasoning per mode.
enum PracticeMode { learn, practice, exam }

class QuestionUiModel {
  const QuestionUiModel({
    required this.questionId,
    required this.topicIds,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.textbookReference,
  });

  final String questionId;

  /// Decision 011: a question may tag multiple topics. Wrong answers
  /// must be attributed to every tagged topic in Focus Areas / weakest
  /// topic calculations.
  final List<String> topicIds;

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  /// Optional per PRD's Textbook-Based References requirement — degrades
  /// gracefully (line simply doesn't render) when absent.
  final String? textbookReference;
}

/// Transient, session-scoped state for one question during a single
/// PracticeScreen session. Not persisted beyond the session except via
/// the (mocked) Attempt write on submit.
class QuestionAttemptState {
  QuestionAttemptState();

  int? selectedIndex;

  /// Learn/Practice: true once "Submit Answer" is tapped (feedback
  /// becomes visible). Exam: true as soon as an option is selected —
  /// exam questions have no separate submit step, selecting IS
  /// answering (Decision: matches real exam-taking behavior where you
  /// can change your answer freely until you submit the whole exam).
  bool isSubmitted = false;

  /// Exam Mode only. Session-scoped — cleared automatically on submit,
  /// never persisted as domain data. Deliberately distinct from
  /// Bookmark (see mock/bookmark store) which persists across sessions.
  bool isFlagged = false;

  bool get isAnswered => selectedIndex != null;
}

/// Official EUEE pacing configuration — never user-entered, computed
/// proportionally from question count. See UX spec §5.
class ExamPacingConfig {
  const ExamPacingConfig._();

  static const int officialExamDurationMinutes = 210;
  static const int officialQuestionCount = 180;

  static double get officialSecondsPerQuestion =>
      (officialExamDurationMinutes * 60) / officialQuestionCount;

  static int sessionTimeSeconds(int questionCount) =>
      (questionCount * officialSecondsPerQuestion).round();
}
