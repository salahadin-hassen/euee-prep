// TEMPORARY MOCK DATA SOURCE.
//
// Stands in for the real repository/provider until Riverpod/Drift are
// wired up.
//
// TODO(integration): delete once a real provider supplies
// QuestionUiModel instances from the Question repository, scoped to
// this chapter's Topics via the many-to-many join (Decision 011).

import '../models/practice_models.dart';

class MockPracticeQuestions {
  MockPracticeQuestions._();

  static List<QuestionUiModel> forChapter(String chapterId) {
    return const [
      QuestionUiModel(
        questionId: 'q1',
        topicIds: ['work-energy-theorem'],
        prompt: 'A ball is thrown upward with initial velocity 20 m/s. '
            'What is its velocity at the highest point?',
        options: ['20 m/s', '0 m/s', '10 m/s', '-20 m/s'],
        correctIndex: 1,
        explanation: 'At the highest point, vertical velocity momentarily '
            'equals zero before the object falls back down.',
        textbookReference: 'Grade 10 Physics, Ch. 4, p. 87',
      ),
      QuestionUiModel(
        questionId: 'q2',
        topicIds: ['kinetic-energy', 'work-energy-theorem'],
        prompt: 'A 2 kg object moves at 3 m/s. What is its kinetic energy?',
        options: ['6 J', '9 J', '18 J', '3 J'],
        correctIndex: 1,
        explanation: 'KE = ½mv² = ½ × 2 × 3² = 9 J. This question also '
            'draws on the Work-Energy Theorem to interpret the result.',
        textbookReference: 'Grade 10 Physics, Ch. 4, p. 91',
      ),
      QuestionUiModel(
        questionId: 'q3',
        topicIds: ['power'],
        prompt: 'What is the SI unit of Power?',
        options: ['Joule', 'Newton', 'Watt', 'Pascal'],
        correctIndex: 2,
        explanation: 'Power is measured in Watts (W), where 1 W = 1 J/s.',
        textbookReference: null,
      ),
      QuestionUiModel(
        questionId: 'q4',
        topicIds: ['kinetic-energy'],
        prompt: 'Doubling an object\'s velocity (mass constant) multiplies '
            'its kinetic energy by:',
        options: ['2', '4', '8', '1'],
        correctIndex: 1,
        explanation: 'KE ∝ v², so doubling velocity quadruples kinetic '
            'energy.',
        textbookReference: 'Grade 10 Physics, Ch. 4, p. 90',
      ),
      QuestionUiModel(
        questionId: 'q5',
        topicIds: ['work-energy-theorem'],
        prompt: 'A force of 10 N moves an object 5 m in the direction of '
            'the force. How much work is done?',
        options: ['2 J', '15 J', '50 J', '0.5 J'],
        correctIndex: 2,
        explanation: 'Work = Force × distance = 10 × 5 = 50 J.',
        textbookReference: 'Grade 10 Physics, Ch. 4, p. 85',
      ),
      QuestionUiModel(
        questionId: 'q6',
        topicIds: ['power'],
        prompt: 'A machine does 300 J of work in 5 seconds. What is its '
            'power output?',
        options: ['60 W', '1500 W', '305 W', '6 W'],
        correctIndex: 0,
        explanation: 'Power = Work / time = 300 / 5 = 60 W.',
        textbookReference: 'Grade 10 Physics, Ch. 4, p. 93',
      ),
    ];
  }
}
