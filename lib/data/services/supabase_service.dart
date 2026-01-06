import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quiz_master/core/constants/app_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  // ========== AUTH METHODS ==========
  Future<AuthResponse> signUp(
    String email,
    String password,
    String name, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userData = <String, dynamic>{'name': name};
      if (additionalData != null) userData.addAll(additionalData);

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );

      if (response.user != null) {
        await _createUserProfile(
          response.user!.id,
          email,
          name,
          additionalData: additionalData,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;

  // ========== USER PROFILE METHODS ==========
  Future<void> _createUserProfile(
    String userId,
    String email,
    String name, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final profileData = <String, dynamic>{
        'id': userId,
        'email': email,
        'name': name,
        'total_score': 0,
        'total_quizzes': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (additionalData != null) profileData.addAll(additionalData);

      await client.from('users').insert(profileData);
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final data = await client.from('users').select().eq('id', userId);
      if (data.isNotEmpty) {
        return data.first;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await client.from('users').update(updates).eq('id', userId);
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  // ========== CATEGORY METHODS ==========
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await client.from('categories').select().order('name');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // ========== QUESTION METHODS ==========
  Future<List<Map<String, dynamic>>> getQuestionsByCategory(
    String categoryId, {
    int limit = 10,
    String? difficulty,
  }) async {
    try {
      if (difficulty != null && difficulty.isNotEmpty) {
        final response = await client
            .from('questions')
            .select()
            .eq('category_id', categoryId)
            .eq('difficulty', difficulty)
            .limit(limit)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response as List);
      } else {
        final response = await client
            .from('questions')
            .select()
            .eq('category_id', categoryId)
            .limit(limit)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response as List);
      }
    } catch (e) {
      print('Error getting questions: $e');
      return [];
    }
  }

  // ========== QUIZ SESSION METHODS ==========
  Future<void> saveQuizSession(Map<String, dynamic> sessionData) async {
    try {
      await client.from('quiz_sessions').insert(sessionData);

      final userId = sessionData['user_id'];
      if (userId != null) {
        final userProfile = await getUserProfile(userId.toString());
        if (userProfile != null) {
          final currentScore = userProfile['total_score'] ?? 0;
          final currentQuizzes = userProfile['total_quizzes'] ?? 0;
          final newScore = currentScore + (sessionData['score'] ?? 0);

          await updateUserProfile(userId.toString(), {
            'total_score': newScore,
            'total_quizzes': currentQuizzes + 1,
          });
        }
      }
    } catch (e) {
      print('Error saving quiz session: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserQuizSessions(String userId) async {
    try {
      final response = await client
          .from('quiz_sessions')
          .select('*, categories(name)')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error getting quiz sessions: $e');
      return [];
    }
  }

  // ========== USER PROGRESS METHODS ==========
  Future<void> updateUserProgress(
    String userId,
    String categoryId,
    int score,
  ) async {
    try {
      final existingProgress = await getUserProgress(userId, categoryId);

      if (existingProgress != null) {
        await client
            .from('user_progress')
            .update({
              'highest_score': score > (existingProgress['highest_score'] ?? 0)
                  ? score
                  : existingProgress['highest_score'],
              'attempts': (existingProgress['attempts'] ?? 0) + 1,
              'last_played': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('category_id', categoryId);
      } else {
        await client.from('user_progress').insert({
          'user_id': userId,
          'category_id': categoryId,
          'highest_score': score,
          'attempts': 1,
          'last_played': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error updating user progress: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProgress(
    String userId,
    String categoryId,
  ) async {
    try {
      final data = await client
          .from('user_progress')
          .select()
          .eq('user_id', userId)
          .eq('category_id', categoryId);

      if (data.isNotEmpty) {
        return data.first;
      }

      return null;
    } catch (e) {
      print('Error getting user progress: $e');
      return null;
    }
  }

  // ========== LEADERBOARD METHODS ==========
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      final response = await client
          .from('users')
          .select('id, name, email, total_score, total_quizzes')
          .order('total_score', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  // ========== DAILY CHALLENGE METHODS ==========
  Future<Map<String, dynamic>?> getDailyChallenge() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final data = await client
          .from('daily_challenges')
          .select('*, categories(name, color)')
          .eq('date', today);

      if (data.isNotEmpty) {
        return data.first;
      }

      return null;
    } catch (e) {
      print('Error getting daily challenge: $e');
      return null;
    }
  }

  // ========== UTILITY METHODS ==========
  Future<void> insertSampleData() async {
    try {
      final existingCategories = await getCategories();
      if (existingCategories.isEmpty) {
        await client.from('categories').insert([
          {
            'name': 'Science',
            'description': 'Test your science knowledge',
            'icon': '🔬',
            'color': '#4CAF50',
            'question_count': 50,
          },
          {
            'name': 'History',
            'description': 'Historical facts and events',
            'icon': '📜',
            'color': '#FF9800',
            'question_count': 45,
          },
          {
            'name': 'Geography',
            'description': 'World geography questions',
            'icon': '🌍',
            'color': '#2196F3',
            'question_count': 40,
          },
          {
            'name': 'Mathematics',
            'description': 'Math problems and concepts',
            'icon': '🧮',
            'color': '#9C27B0',
            'question_count': 35,
          },
        ]);
      }
    } catch (e) {
      print('Error inserting sample data: $e');
    }
  }
}
