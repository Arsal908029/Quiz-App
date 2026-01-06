class QuizSessionModel {
  final String id;
  final String userId;
  final String? categoryId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int? timeTaken;
  final DateTime completedAt;

  QuizSessionModel({
    required this.id,
    required this.userId,
    this.categoryId,
    this.score = 0,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.timeTaken,
    required this.completedAt,
  });

  factory QuizSessionModel.fromJson(Map<String, dynamic> json) {
    return QuizSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      timeTaken: json['time_taken'] as int?,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'score': score,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'time_taken': timeTaken,
    };
  }

  double get accuracy {
    if (totalQuestions == 0) return 0.0;
    return (correctAnswers / totalQuestions) * 100;
  }
}