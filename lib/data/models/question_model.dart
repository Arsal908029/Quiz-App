import 'dart:convert';

class QuestionModel {
  final String id;
  final String categoryId;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String difficulty;
  final int points;

  QuestionModel({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.difficulty = 'medium',
    this.points = 10,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Handle options which could be JSON array or string
    List<String> optionsList = [];
    
    if (json['options'] is String) {
      // Parse string JSON
      try {
        final List<dynamic> parsed = jsonDecode(json['options']);
        optionsList = parsed.map((e) => e.toString()).toList();
      } catch (e) {
        optionsList = [json['options'].toString()];
      }
    } else if (json['options'] is List) {
      // Already a list
      optionsList = (json['options'] as List).map((e) => e.toString()).toList();
    } else {
      // Default fallback
      optionsList = ['Option A', 'Option B', 'Option C', 'Option D'];
    }
    
    return QuestionModel(
      id: json['id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: optionsList,
      correctAnswer: json['correct_answer']?.toString() ?? '',
      explanation: json['explanation']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'medium',
      points: (json['points'] as int?) ?? 10,
    );
  }

  bool isCorrect(String answer) {
    return answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'points': points,
    };
  }
}