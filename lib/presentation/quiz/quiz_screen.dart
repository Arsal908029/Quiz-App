import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quiz_master/core/widgets/animated_background.dart';
import 'package:quiz_master/core/widgets/glass_card.dart';
import 'package:quiz_master/data/models/question_model.dart';
import 'package:quiz_master/data/services/supabase_service.dart';
import 'package:quiz_master/presentation/quiz/quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const QuizScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuestionModel> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _selectedAnswerIndex = -1;
  bool _isAnswerSelected = false;
  bool _isLoading = true;
  List<int> _userAnswers = [];
  DateTime? _startTime;
  
  // Timer variables
  late Timer _timer;
  int _secondsRemaining = 600; // 10 minutes = 600 seconds
  bool _isTimeUp = false;
  bool _showTimeWarning = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
            
            // Show warning when less than 60 seconds remain
            if (_secondsRemaining <= 60 && !_showTimeWarning) {
              _showTimeWarning = true;
            }
            
            // Flash warning when less than 30 seconds
            if (_secondsRemaining <= 30) {
              _showTimeWarning = !_showTimeWarning;
            }
          });
        }
      } else {
        _timer.cancel();
        if (mounted) {
          setState(() {
            _isTimeUp = true;
          });
        }
        _showTimeUpDialog();
      }
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff151C35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.timer_off_rounded, color: Colors.redAccent),
            const SizedBox(width: 12),
            Text(
              'Time\'s Up!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Your time has run out. The quiz will be submitted automatically.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeQuiz();
            },
            child: Text(
              'View Results',
              style: GoogleFonts.outfit(color: const Color(0xff00E5FF), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadQuestions() async {
    try {
      final questionsData = await SupabaseService()
          .getQuestionsByCategory(widget.categoryId, limit: 10);
      
      final questions = questionsData
          .map((data) => QuestionModel.fromJson(data))
          .toList();
      
      if (mounted) {
        setState(() {
          _questions = questions;
          _userAnswers = List.filled(questions.length, -1);
          _isLoading = false;
        });
      }
      
      // Start timer after questions are loaded
      _startTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectAnswer(int index) {
    if (_isAnswerSelected || _isTimeUp) return;

    if (mounted) {
      setState(() {
        _selectedAnswerIndex = index;
        _isAnswerSelected = true;
        _userAnswers[_currentQuestionIndex] = index;
      });
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedAnswer = currentQuestion.options[index];
    
    if (currentQuestion.isCorrect(selectedAnswer)) {
      _score += currentQuestion.points;
    }

    // Move to next question after delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1 && !_isTimeUp) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswerIndex = -1;
          _isAnswerSelected = false;
        });
      } else {
        _completeQuiz();
      }
    });
  }

  void _skipQuestion() {
    if (_isTimeUp) return;
    
    if (mounted) {
      setState(() {
        _userAnswers[_currentQuestionIndex] = -1; // Mark as skipped
        if (_currentQuestionIndex < _questions.length - 1) {
          _currentQuestionIndex++;
          _selectedAnswerIndex = -1;
          _isAnswerSelected = false;
        } else {
          _completeQuiz();
        }
      });
    }
  }

  void _completeQuiz() async {
    // Cancel timer if still running
    if (_timer.isActive) {
      _timer.cancel();
    }
    
    final endTime = DateTime.now();
    final timeTaken = endTime.difference(_startTime!).inSeconds;
    final user = SupabaseService().currentUser;

    if (user != null) {
      final sessionData = {
        'user_id': user.id,
        'category_id': widget.categoryId,
        'score': _score,
        'total_questions': _questions.length,
        'correct_answers': _score ~/ 10, // Assuming 10 points per question
        'time_taken': timeTaken,
      };

      try {
        await SupabaseService().saveQuizSession(sessionData);
        await SupabaseService().updateUserProgress(
          user.id,
          widget.categoryId,
          _score,
        );
      } catch (e) {
        debugPrint('Error saving quiz results: $e');
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          score: _score,
          totalQuestions: _questions.length,
          categoryName: widget.categoryName,
          timeTaken: timeTaken,
          userAnswers: _userAnswers,
          questions: _questions,
        ),
      ),
    );
  }

  double get _progress {
    if (_questions.isEmpty) return 0.0;
    return (_currentQuestionIndex + 1) / _questions.length;
  }

  Widget _buildTimer() {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    
    Color timerColor;
    if (_secondsRemaining <= 30) {
      timerColor = Colors.redAccent;
    } else if (_secondsRemaining <= 60) {
      timerColor = Colors.orangeAccent;
    } else {
      timerColor = const Color(0xff00E5FF);
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _showTimeWarning && _secondsRemaining <= 60 
            ? Colors.redAccent.withValues(alpha: 0.25)
            : timerColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _showTimeWarning && _secondsRemaining <= 60
              ? Colors.redAccent
              : timerColor,
          width: _showTimeWarning && _secondsRemaining <= 60 ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: _secondsRemaining <= 60 ? Colors.redAccent : timerColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$minutes:$seconds',
            style: GoogleFonts.outfit(
              color: _secondsRemaining <= 60 ? Colors.redAccent : timerColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: PremiumBackgroundWrapper(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(child: CircularProgressIndicator(color: Color(0xff00E5FF))),
              const SizedBox(height: 20),
              Text(
                'Loading challenges...',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: PremiumBackgroundWrapper(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                glowColor: Colors.redAccent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No questions available',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for ${widget.categoryName} questions',
                      style: GoogleFonts.poppins(color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.transparent, // Background wrapper visible
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          // Skip button in app bar
          if (!_isAnswerSelected && !_isTimeUp && _currentQuestionIndex < _questions.length - 1)
            TextButton(
              onPressed: _skipQuestion,
              child: Text(
                'Skip',
                style: GoogleFonts.outfit(color: const Color(0xff00E5FF), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: Column(
            children: [
              // Progress Bar with Timer
              GlassCard(
                borderRadius: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                backgroundOpacity: 0.04,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            _buildTimer(),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '$_score pts',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white12,
                        color: const Color(0xff7C4DFF),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Time warning banner
              if (_showTimeWarning && _secondsRemaining <= 60)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _secondsRemaining <= 30 
                            ? 'Hurry! Only $_secondsRemaining seconds left!' 
                            : 'Less than a minute remaining!',
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // Question Card & Options (Animated on index change)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    key: ValueKey<int>(_currentQuestionIndex), // Triggers animation on new question
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Glass Card Question Layout
                      GlassCard(
                        glowColor: const Color(0xff7C4DFF),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Difficulty Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(currentQuestion.difficulty).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _getDifficultyColor(currentQuestion.difficulty).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    currentQuestion.difficulty.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      color: _getDifficultyColor(currentQuestion.difficulty),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                
                                // Points Badge
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${currentQuestion.points} pts',
                                      style: GoogleFonts.outfit(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentQuestion.question,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

                      const SizedBox(height: 24),

                      Text(
                        'Select your answer:',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white60,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Build the multiple choice items with entrance delays
                      ...currentQuestion.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        
                        Color glowColor = Colors.transparent;
                        double borderOpacity = 0.15;
                        double backgroundOpacity = 0.05;
                        Color textColor = Colors.white70;
                        IconData? iconData;

                        if (_isAnswerSelected) {
                          if (index == _selectedAnswerIndex) {
                            final isCorrect = currentQuestion.isCorrect(option);
                            glowColor = isCorrect ? Colors.green : Colors.red;
                            borderOpacity = 0.5;
                            backgroundOpacity = 0.15;
                            textColor = isCorrect ? Colors.greenAccent : Colors.redAccent;
                            iconData = isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;
                          } else if (currentQuestion.isCorrect(option)) {
                            glowColor = Colors.green;
                            borderOpacity = 0.4;
                            backgroundOpacity = 0.1;
                            textColor = Colors.greenAccent;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: _isTimeUp ? null : () => _selectAnswer(index),
                            child: GlassCard(
                              glowColor: glowColor != Colors.transparent ? glowColor : null,
                              borderOpacity: borderOpacity,
                              backgroundOpacity: backgroundOpacity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              borderRadius: 18,
                              child: Row(
                                children: [
                                  // Question Option Index Badge (A, B, C, D)
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: glowColor != Colors.transparent ? glowColor : Colors.white24,
                                        width: 1.5,
                                      ),
                                      color: glowColor != Colors.transparent 
                                          ? glowColor.withValues(alpha: 0.2) 
                                          : Colors.white.withValues(alpha: 0.04),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index),
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (iconData != null)
                                    Icon(
                                      iconData,
                                      color: glowColor,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ).animate()
                         .fadeIn(delay: (100 * index).ms, duration: 300.ms)
                         .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
                      }),

                      const SizedBox(height: 16),

                      // Bottom Skip Button (if unanswered)
                      if (!_isAnswerSelected && !_isTimeUp && _currentQuestionIndex < _questions.length - 1)
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _skipQuestion,
                            icon: const Icon(Icons.skip_next_rounded),
                            label: const Text('Skip Question'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xff00E5FF),
                              side: const BorderSide(color: Color(0xff00E5FF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),

                      // Answer Explanation Box
                      if (_isAnswerSelected && currentQuestion.explanation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: GlassCard(
                            glowColor: const Color(0xff00E5FF),
                            padding: const EdgeInsets.all(16),
                            borderRadius: 18,
                            backgroundOpacity: 0.08,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lightbulb_outline_rounded,
                                      color: Color(0xff00E5FF),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Explanation',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xff00E5FF),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentQuestion.explanation!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              ),

              // Bottom Next Question / Submit Button (if answered)
              if (_isAnswerSelected || _isTimeUp)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff151C35).withValues(alpha: 0.8),
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff7C4DFF).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentQuestionIndex < _questions.length - 1 && !_isTimeUp) {
                          setState(() {
                            _currentQuestionIndex++;
                            _selectedAnswerIndex = -1;
                            _isAnswerSelected = false;
                          });
                        } else {
                          _completeQuiz();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentQuestionIndex < _questions.length - 1 && !_isTimeUp
                                ? 'Next Question'
                                : 'Submit Quiz',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentQuestionIndex < _questions.length - 1 && !_isTimeUp
                                ? Icons.arrow_forward_rounded
                                : Icons.done_all_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.greenAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'hard':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}