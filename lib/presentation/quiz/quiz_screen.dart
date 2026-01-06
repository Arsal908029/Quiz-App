import 'dart:async';
import 'package:flutter/material.dart';
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
      } else {
        _timer.cancel();
        setState(() {
          _isTimeUp = true;
        });
        _showTimeUpDialog();
      }
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.red),
            SizedBox(width: 10),
            Text('Time\'s Up!'),
          ],
        ),
        content: const Text('Your time has run out. The quiz will be submitted automatically.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeQuiz();
            },
            child: const Text('View Results'),
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
      
      setState(() {
        _questions = questions;
        _userAnswers = List.filled(questions.length, -1);
        _isLoading = false;
      });
      
      // Start timer after questions are loaded
      _startTimer();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(int index) {
    if (_isAnswerSelected || _isTimeUp) return;

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswerSelected = true;
      _userAnswers[_currentQuestionIndex] = index;
    });

    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedAnswer = currentQuestion.options[index];
    
    if (currentQuestion.isCorrect(selectedAnswer)) {
      _score += currentQuestion.points;
    }

    // Move to next question after delay
    Future.delayed(const Duration(seconds: 1), () {
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

      await SupabaseService().saveQuizSession(sessionData);
      await SupabaseService().updateUserProgress(
        user.id,
        widget.categoryId,
        _score,
      );
    }

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
      timerColor = Colors.red;
    } else if (_secondsRemaining <= 60) {
      timerColor = Colors.orange;
    } else {
      timerColor = Theme.of(context).colorScheme.primary;
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _showTimeWarning && _secondsRemaining <= 60 
            ? Colors.red.withOpacity(0.2)
            : timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _showTimeWarning && _secondsRemaining <= 60
              ? Colors.red
              : timerColor,
          width: _showTimeWarning && _secondsRemaining <= 60 ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: _secondsRemaining <= 60 ? Colors.red : timerColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$minutes:$seconds',
            style: TextStyle(
              color: _secondsRemaining <= 60 ? Colors.red : timerColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
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
        appBar: AppBar(
          title: Text(widget.categoryName),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryName),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No questions available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for ${widget.categoryName} questions',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
        actions: [
          // Skip button in app bar
          if (!_isAnswerSelected && !_isTimeUp && _currentQuestionIndex < _questions.length - 1)
            TextButton(
              onPressed: _skipQuestion,
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar with Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                border: _showTimeWarning && _secondsRemaining <= 60
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          _buildTimer(),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Text(
                              '$_score pts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[200],
                    color: Theme.of(context).colorScheme.primary,
                    minHeight: 8,
                  ),
                ],
              ),
            ),

            // Time warning banner
            if (_showTimeWarning && _secondsRemaining <= 60)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.red.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _secondsRemaining <= 30 
                          ? 'Hurry! Only $_secondsRemaining seconds left!' 
                          : 'Less than a minute remaining!',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Question Card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question card with category info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question difficulty badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(currentQuestion.difficulty)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              currentQuestion.difficulty.toUpperCase(),
                              style: TextStyle(
                                color: _getDifficultyColor(currentQuestion.difficulty),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentQuestion.question,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Points indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${currentQuestion.points} points',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Options
                    Text(
                      'Select your answer:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),

                    ...currentQuestion.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      
                      Color backgroundColor = Colors.transparent;
                      Color borderColor = Colors.grey[300]!;
                      Color textColor = Colors.black;
                      IconData? iconData;

                      if (_isAnswerSelected) {
                        if (index == _selectedAnswerIndex) {
                          backgroundColor = currentQuestion.isCorrect(option)
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1);
                          borderColor = currentQuestion.isCorrect(option)
                              ? Colors.green
                              : Colors.red;
                          textColor = currentQuestion.isCorrect(option)
                              ? Colors.green
                              : Colors.red;
                          iconData = currentQuestion.isCorrect(option)
                              ? Icons.check_circle
                              : Icons.cancel;
                        } else if (currentQuestion.isCorrect(option)) {
                          backgroundColor = Colors.green.withOpacity(0.1);
                          borderColor = Colors.green;
                          textColor = Colors.green;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: _isTimeUp ? null : () => _selectAnswer(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: borderColor),
                                    color: backgroundColor,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index), // A, B, C, D
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (iconData != null)
                                  Icon(
                                    iconData,
                                    color: currentQuestion.isCorrect(option)
                                        ? Colors.green
                                        : Colors.red,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Skip button at bottom
                    if (!_isAnswerSelected && !_isTimeUp && _currentQuestionIndex < _questions.length - 1)
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _skipQuestion,
                          icon: const Icon(Icons.skip_next),
                          label: const Text('Skip Question'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),

                    // Explanation (if answer selected)
                    if (_isAnswerSelected && currentQuestion.explanation != null)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Explanation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentQuestion.explanation!,
                              style: TextStyle(
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Next/Submit Button
            if (_isAnswerSelected || _isTimeUp)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentQuestionIndex < _questions.length - 1 && !_isTimeUp
                              ? 'Next Question'
                              : 'Submit Quiz',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentQuestionIndex < _questions.length - 1 && !_isTimeUp
                              ? Icons.arrow_forward
                              : Icons.done_all,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}