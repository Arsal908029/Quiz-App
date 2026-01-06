// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:quiz_master/data/models/question_model.dart';

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String categoryName;
  final int timeTaken;
  final List<int> userAnswers;
  final List<QuestionModel> questions;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.categoryName,
    required this.timeTaken,
    required this.userAnswers,
    required this.questions,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late ConfettiController _confettiController;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Trigger confetti if score is high (use actual max score)
    final maxScore = widget.questions.fold<int>(0, (sum, q) => sum + q.points);
    final percentage = maxScore > 0 ? (widget.score / maxScore) * 100 : 0.0;
    if (percentage >= 70) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  double get _percentage {
    final maxScore = widget.questions.fold<int>(0, (sum, q) => sum + q.points);
    if (maxScore <= 0) return 0.0;
    final pct = widget.score / maxScore;
    // Clamp to valid range [0.0, 1.0]
    return pct.isFinite ? pct.clamp(0.0, 1.0).toDouble() : 0.0;
  }

  String get _performanceText {
    if (_percentage >= 0.9) return 'Excellent! 🎉';
    if (_percentage >= 0.7) return 'Great Job! 👍';
    if (_percentage >= 0.5) return 'Good Effort! 😊';
    return 'Keep Practicing! 💪';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Result Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        Theme.of(context).colorScheme.primary,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Quiz Complete!',
                        style: Theme.of(
                          context,
                        ).textTheme.displayLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.categoryName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Score Circle
                      CircularPercentIndicator(
                        radius: 80,
                        lineWidth: 12,
                        percent: _percentage,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${widget.score}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'points',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        progressColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),

                      const SizedBox(height: 30),

                      Text(
                        _performanceText,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Cards
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle,
                          value: '${widget.score ~/ 10}',
                          label: 'Correct',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer,
                          value: '${widget.timeTaken}s',
                          label: 'Time',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.percent,
                          value: '${(_percentage * 100).toStringAsFixed(1)}%',
                          label: 'Accuracy',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                              child: const Text('Back to Categories'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                );
                              },
                              child: const Text('Play Again'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showDetails = !_showDetails;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showDetails ? 'Hide Details' : 'View Details',
                            ),
                            Icon(
                              _showDetails
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Question Details
                if (_showDetails)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Question Review',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...widget.questions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final question = entry.value;
                          final userAnswerIndex = widget.userAnswers[index];
                          final isCorrect =
                              userAnswerIndex != -1 &&
                              question.isCorrect(
                                question.options[userAnswerIndex],
                              );

                          return _buildQuestionReview(
                            index,
                            question,
                            userAnswerIndex,
                            isCorrect,
                          );
                        }),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // Confetti
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuestionReview(
    int index,
    QuestionModel question,
    int userAnswerIndex,
    bool isCorrect,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
                child: Center(
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Q${index + 1}: ${question.question}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (userAnswerIndex != -1)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your answer: ${question.options[userAnswerIndex]}',
                  style: TextStyle(
                    color: isCorrect ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

          Text(
            'Correct answer: ${question.correctAnswer}',
            style: TextStyle(
              color: Colors.green[800],
              fontWeight: FontWeight.w500,
            ),
          ),

          if (question.explanation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '💡 ${question.explanation!}',
                style: TextStyle(color: Colors.blue[800], fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
