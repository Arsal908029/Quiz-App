
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:lottie/lottie.dart';
import 'package:quiz_master/core/widgets/animated_background.dart';
import 'package:quiz_master/core/widgets/glass_card.dart';
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
      duration: const Duration(seconds: 4),
    );

    // Trigger confetti if score is high
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
    return pct.isFinite ? pct.clamp(0.0, 1.0).toDouble() : 0.0;
  }

  String get _performanceText {
    if (_percentage >= 0.9) return 'Excellent Performance! 🎉';
    if (_percentage >= 0.7) return 'Great Job! 👍';
    if (_percentage >= 0.5) return 'Good Effort! 😊';
    return 'Keep Practicing! 💪';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background visible
      body: PremiumBackgroundWrapper(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 36),
                  
                  // Trophy Animation Header Card
                  GlassCard(
                    glowColor: const Color(0xff7C4DFF),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          'Quiz Complete!',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.categoryName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Beautiful Lottie Trophy Animation
                        SizedBox(
                          height: 160,
                          child: Lottie.network(
                            'https://fonts.gstatic.com/s/i/short-term/release/googlegifs/trophy/v6/medium.gif', // Safe, stable Google hosting for trophy graphic
                            width: 160,
                            height: 160,
                            errorBuilder: (context, error, stackTrace) {
                              return Lottie.network(
                                'https://assets9.lottiefiles.com/packages/lf20_a3j5y0c1.json', // Alternate community package
                                errorBuilder: (ctx, err, st) {
                                  return const Center(
                                    child: Text(
                                      '🏆',
                                      style: TextStyle(fontSize: 80),
                                    ),
                                  );
                                }
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                        // Score percent indicator
                        CircularPercentIndicator(
                          radius: 54,
                          lineWidth: 8,
                          percent: _percentage,
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${widget.score}',
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'points',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          progressColor: const Color(0xff00E5FF),
                          backgroundColor: Colors.white10,
                          circularStrokeCap: CircularStrokeCap.round,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          _performanceText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats overview cards row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle_outline_rounded,
                          value: '${widget.score ~/ 10}',
                          label: 'Correct',
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer_outlined,
                          value: '${widget.timeTaken}s',
                          label: 'Time Taken',
                          color: const Color(0xff00E5FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.percent_rounded,
                          value: '${(_percentage * 100).toStringAsFixed(0)}%',
                          label: 'Accuracy',
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Actions Buttons
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xff00E5FF)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Categories',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.popUntil(
                                    context,
                                    (route) => route.isFirst,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Play Again',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showDetails = !_showDetails;
                          });
                        },
                        icon: Icon(
                          _showDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: const Color(0xff00E5FF),
                        ),
                        label: Text(
                          _showDetails ? 'Hide Review Details' : 'View Question Review',
                          style: GoogleFonts.outfit(
                            color: const Color(0xff00E5FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Question Review Details List
                  if (_showDetails) ...[
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Question Review',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...widget.questions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      final userAnswerIndex = widget.userAnswers[index];
                      final isCorrect = userAnswerIndex != -1 &&
                          question.isCorrect(question.options[userAnswerIndex]);

                      return _buildQuestionReview(
                        index,
                        question,
                        userAnswerIndex,
                        isCorrect,
                      );
                    }),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Confetti Cannon Overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xff7C4DFF),
                  Color(0xff00E5FF),
                  Colors.pinkAccent,
                  Colors.amber,
                  Colors.greenAccent,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return GlassCard(
      glowColor: color,
      padding: const EdgeInsets.all(12),
      borderRadius: 18,
      backgroundOpacity: 0.05,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
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
    final cardColor = isCorrect ? Colors.greenAccent : Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        glowColor: cardColor,
        borderOpacity: 0.2,
        backgroundOpacity: 0.04,
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor.withValues(alpha: 0.2),
                    border: Border.all(color: cardColor, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      isCorrect ? Icons.check : Icons.close,
                      size: 14,
                      color: cardColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Q${index + 1}: ${question.question}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (userAnswerIndex != -1) ...[
              Text(
                'Your Answer: ${question.options[userAnswerIndex]}',
                style: GoogleFonts.poppins(
                  color: cardColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              'Correct Answer: ${question.correctAnswer}',
              style: GoogleFonts.poppins(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (question.explanation != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff00E5FF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xff00E5FF)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        question.explanation!,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
