class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final int totalScore;
  final int totalQuizzes;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.totalScore = 0,
    this.totalQuizzes = 0,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      totalScore: json['total_score'] as int? ?? 0,
      totalQuizzes: json['total_quizzes'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'total_score': totalScore,
      'total_quizzes': totalQuizzes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}