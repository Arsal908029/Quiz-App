import 'package:flutter/foundation.dart';
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
      debugPrint('Error creating user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final data = await client.from('users').select().eq('id', userId);
      if (data.isNotEmpty) {
        return data.first;
      }
      
      // Self-healing: if the user exists in Auth but not in public.users, create it!
      final user = client.auth.currentUser;
      if (user != null && user.id == userId) {
        final email = user.email;
        final name = user.userMetadata?['name'] as String? ?? email?.split('@').first ?? 'User';
        
        final profileData = <String, dynamic>{
          'id': userId,
          'email': email,
          'name': name,
          'total_score': 0,
          'total_quizzes': 0,
          'created_at': DateTime.now().toIso8601String(),
        };
        
        try {
          await client.from('users').insert(profileData);
          // Query again to get the inserted profile
          final retryData = await client.from('users').select().eq('id', userId);
          if (retryData.isNotEmpty) {
            return retryData.first;
          }
        } catch (insertError) {
          debugPrint('Self-healing profile creation failed: $insertError');
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
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
      debugPrint('Error updating user profile: $e');
    }
  }

  // ========== CATEGORY METHODS ==========
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await client.from('categories').select().order('name');
      final list = List<Map<String, dynamic>>.from(response as List);
      if (list.isEmpty) {
        // Automatically seed the database if categories table is empty!
        await seedDatabase();
        final seedResponse = await client.from('categories').select().order('name');
        return List<Map<String, dynamic>>.from(seedResponse as List);
      }
      return list;
    } catch (e) {
      debugPrint('Error getting categories: $e');
      rethrow;
    }
  }

  Future<void> seedDatabase() async {
    try {
      // 1. Insert Categories
      final categoriesToInsert = [
        {
          'name': 'Science',
          'description': 'Test your science knowledge',
          'icon': '🔬',
          'color': '#4CAF50',
          'question_count': 5,
        },
        {
          'name': 'History',
          'description': 'Historical facts and events',
          'icon': '📜',
          'color': '#FF9800',
          'question_count': 5,
        },
        {
          'name': 'Geography',
          'description': 'World geography questions',
          'icon': '🌍',
          'color': '#2196F3',
          'question_count': 5,
        },
        {
          'name': 'Mathematics',
          'description': 'Math problems and concepts',
          'icon': '🧮',
          'color': '#9C27B0',
          'question_count': 5,
        },
        {
          'name': 'Technology',
          'description': 'Computers, programming, and tech history',
          'icon': '💻',
          'color': '#607D8B',
          'question_count': 5,
        },
        {
          'name': 'Sports',
          'description': 'Athletes, rules, and sporting events',
          'icon': '⚽',
          'color': '#E91E63',
          'question_count': 5,
        },
        {
          'name': 'Entertainment',
          'description': 'Movies, music, pop culture, and books',
          'icon': '🎬',
          'color': '#FF5722',
          'question_count': 5,
        },
        {
          'name': 'General Knowledge',
          'description': 'A mix of trivia across diverse subjects',
          'icon': '🧠',
          'color': '#00BCD4',
          'question_count': 5,
        },
      ];

      final categoriesResponse = await client
          .from('categories')
          .insert(categoriesToInsert)
          .select();

      if (categoriesResponse.isEmpty) return;

      // Map category name to its inserted ID
      final categoryMap = <String, String>{};
      for (var cat in categoriesResponse) {
        categoryMap[cat['name'].toString()] = cat['id'].toString();
      }

      // 2. Insert Questions
      final questionsToInsert = <Map<String, dynamic>>[];

      // Science Questions
      final scienceId = categoryMap['Science'];
      if (scienceId != null) {
        questionsToInsert.addAll([
          {
            'category_id': scienceId,
            'question': 'What is the chemical symbol for water?',
            'options': ['H2O', 'O2', 'CO2', 'H2'],
            'correct_answer': 'H2O',
            'explanation': 'Water is made of two hydrogen atoms and one oxygen atom.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': scienceId,
            'question': 'Which planet is known as the Red Planet?',
            'options': ['Earth', 'Mars', 'Jupiter', 'Saturn'],
            'correct_answer': 'Mars',
            'explanation': 'Mars appears red due to iron oxide (rust) on its surface.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': scienceId,
            'question': 'What gas do plants absorb from the atmosphere for photosynthesis?',
            'options': ['Oxygen', 'Carbon Dioxide', 'Nitrogen', 'Hydrogen'],
            'correct_answer': 'Carbon Dioxide',
            'explanation': 'Plants absorb carbon dioxide (CO2) and release oxygen (O2) during photosynthesis.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': scienceId,
            'question': 'What is the powerhouse of the cell?',
            'options': ['Nucleus', 'Ribosome', 'Mitochondria', 'Golgi Apparatus'],
            'correct_answer': 'Mitochondria',
            'explanation': 'Mitochondria generate most of the chemical energy needed to power the cell.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': scienceId,
            'question': 'What is the speed of light in a vacuum (approximately)?',
            'options': ['150,000 km/s', '300,000 km/s', '450,000 km/s', '600,000 km/s'],
            'correct_answer': '300,000 km/s',
            'explanation': 'The speed of light in vacuum is approximately 300,000 km/s.',
            'difficulty': 'hard',
            'points': 20,
          },
        ]);
      }

      // History Questions
      final historyId = categoryMap['History'];
      if (historyId != null) {
        questionsToInsert.addAll([
          {
            'category_id': historyId,
            'question': 'In which year did World War II end?',
            'options': ['1918', '1939', '1945', '1950'],
            'correct_answer': '1945',
            'explanation': 'World War II ended in September 1945 with the formal surrender of Japan.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': historyId,
            'question': 'Who was the first President of the United States?',
            'options': ['Abraham Lincoln', 'Thomas Jefferson', 'George Washington', 'John Adams'],
            'correct_answer': 'George Washington',
            'explanation': 'George Washington served as president from 1789 to 1797.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': historyId,
            'question': 'Who painted the Mona Lisa?',
            'options': ['Michelangelo', 'Raphael', 'Vincent van Gogh', 'Leonardo da Vinci'],
            'correct_answer': 'Leonardo da Vinci',
            'explanation': 'Leonardo da Vinci painted the Mona Lisa in Florence between 1503 and 1519.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': historyId,
            'question': 'Which empire built the Colosseum in Rome?',
            'options': ['Greek Empire', 'Roman Empire', 'Persian Empire', 'Egyptian Empire'],
            'correct_answer': 'Roman Empire',
            'explanation': 'The Colosseum was built by the Roman Empire starting under Emperor Vespasian in 72 AD.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': historyId,
            'question': 'Who was the first human to journey into outer space?',
            'options': ['Neil Armstrong', 'Yuri Gagarin', 'Buzz Aldrin', 'John Glenn'],
            'correct_answer': 'Yuri Gagarin',
            'explanation': 'Cosmonaut Yuri Gagarin was the first human in space.',
            'difficulty': 'hard',
            'points': 20,
          },
        ]);
      }

      // Geography Questions
      final geographyId = categoryMap['Geography'];
      if (geographyId != null) {
        questionsToInsert.addAll([
          {
            'category_id': geographyId,
            'question': 'What is the capital of France?',
            'options': ['London', 'Berlin', 'Paris', 'Rome'],
            'correct_answer': 'Paris',
            'explanation': 'Paris has been the capital of France since the late 10th century.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': geographyId,
            'question': 'Which is the largest ocean on Earth?',
            'options': ['Atlantic Ocean', 'Indian Ocean', 'Arctic Ocean', 'Pacific Ocean'],
            'correct_answer': 'Pacific Ocean',
            'explanation': 'The Pacific Ocean is the largest and deepest of Earth\'s oceanic divisions.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': geographyId,
            'question': 'Which is the longest river in the world?',
            'options': ['Amazon River', 'Nile River', 'Yangtze River', 'Mississippi River'],
            'correct_answer': 'Nile River',
            'explanation': 'The Nile River is traditionally considered the longest in the world.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': geographyId,
            'question': 'What is the smallest country in the world?',
            'options': ['Monaco', 'San Marino', 'Vatican City', 'Liechtenstein'],
            'correct_answer': 'Vatican City',
            'explanation': 'Vatican City is the smallest independent state in the world.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': geographyId,
            'question': 'Which desert is the largest hot desert in the world?',
            'options': ['Gobi Desert', 'Kalahari Desert', 'Sahara Desert', 'Arabian Desert'],
            'correct_answer': 'Sahara Desert',
            'explanation': 'The Sahara is the largest hot desert on Earth.',
            'difficulty': 'hard',
            'points': 20,
          },
        ]);
      }

      // Mathematics Questions
      final mathId = categoryMap['Mathematics'];
      if (mathId != null) {
        questionsToInsert.addAll([
          {
            'category_id': mathId,
            'question': 'What is the square root of 144?',
            'options': ['10', '11', '12', '14'],
            'correct_answer': '12',
            'explanation': '12 multiplied by 12 equals 144.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': mathId,
            'question': 'Solve: 5 * (10 - 3) + 2',
            'options': ['37', '35', '27', '17'],
            'correct_answer': '37',
            'explanation': 'Follow BODMAS/PEMDAS: 10 - 3 = 7. 5 * 7 = 35. 35 + 2 = 37.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': mathId,
            'question': 'What is the value of Pi (to two decimal places)?',
            'options': ['3.12', '3.14', '3.16', '3.18'],
            'correct_answer': '3.14',
            'explanation': 'Pi is approximately 3.14159, which rounds to 3.14.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': mathId,
            'question': 'What is 15% of 200?',
            'options': ['15', '20', '30', '45'],
            'correct_answer': '30',
            'explanation': '15/100 * 200 = 15 * 2 = 30.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': mathId,
            'question': 'If a triangle has sides of 3cm and 4cm, and a right angle between them, what is the length of the hypotenuse?',
            'options': ['5cm', '6cm', '7cm', '8cm'],
            'correct_answer': '5cm',
            'explanation': 'Using Pythagoras: 3^2 + 4^2 = 9 + 16 = 25. Square root of 25 is 5.',
            'difficulty': 'hard',
            'points': 20,
          },
        ]);
      }

      // Technology Questions
      final techId = categoryMap['Technology'];
      if (techId != null) {
        questionsToInsert.addAll([
          {
            'category_id': techId,
            'question': 'What does CPU stand for?',
            'options': ['Central Processing Unit', 'Computer Processing Utility', 'Core Process Unit', 'Control Power Unit'],
            'correct_answer': 'Central Processing Unit',
            'explanation': 'CPU stands for Central Processing Unit, the main processor that executes instructions in a computer.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': techId,
            'question': 'Which programming language is primarily used for the behavior of web pages?',
            'options': ['Python', 'C++', 'Java', 'JavaScript'],
            'correct_answer': 'JavaScript',
            'explanation': 'JavaScript is the core language used to make web pages interactive and dynamic on the client side.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': techId,
            'question': 'Who is known as the co-founder of Microsoft alongside Paul Allen?',
            'options': ['Steve Jobs', 'Bill Gates', 'Mark Zuckerberg', 'Larry Page'],
            'correct_answer': 'Bill Gates',
            'explanation': 'Bill Gates co-founded Microsoft in 1975, which became the world\'s largest personal computer software company.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': techId,
            'question': 'What is the main standard language used to manage relational databases?',
            'options': ['HTML', 'SQL', 'JSON', 'XML'],
            'correct_answer': 'SQL',
            'explanation': 'SQL (Structured Query Language) is the standard language used to interact with relational database management systems.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': techId,
            'question': 'What does HTML stand for?',
            'options': ['HyperText Markup Language', 'HighTransfer Machine Language', 'Hyperlink Text Manage Line', 'Home Tool Markup Language'],
            'correct_answer': 'HyperText Markup Language',
            'explanation': 'HTML stands for HyperText Markup Language, the standard formatting language used for creating web pages.',
            'difficulty': 'hard',
            'points': 20,
          },
        ]);
      }

      // Sports Questions
      final sportsId = categoryMap['Sports'];
      if (sportsId != null) {
        questionsToInsert.addAll([
          {
            'category_id': sportsId,
            'question': 'How many players are on the field for each team in a standard soccer match?',
            'options': ['9', '10', '11', '12'],
            'correct_answer': '11',
            'explanation': 'A standard soccer match is played between two teams of 11 players each, including one goalkeeper.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': sportsId,
            'question': 'Which national team won the FIFA World Cup in Qatar in 2022?',
            'options': ['France', 'Brazil', 'Germany', 'Argentina'],
            'correct_answer': 'Argentina',
            'explanation': 'Argentina won the 2022 FIFA World Cup, defeating France in a penalty shootout after a 3-3 draw.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': sportsId,
            'question': 'What is the approximate length of a standard marathon in miles?',
            'options': ['26.2', '20.5', '30.0', '15.4'],
            'correct_answer': '26.2',
            'explanation': 'A marathon is a long-distance foot race with an official distance of 42.195 kilometers, or 26.2 miles.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': sportsId,
            'question': 'In which sport do players perform slam dunks?',
            'options': ['Tennis', 'Volleyball', 'Basketball', 'Baseball'],
            'correct_answer': 'Basketball',
            'explanation': 'A slam dunk is a type of basketball shot performed when a player jumps in the air and forces the ball through the basket with one or both hands.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': sportsId,
            'question': 'How many rings are on the Olympic flag?',
            'options': ['4', '5', '6', '7'],
            'correct_answer': '5',
            'explanation': 'The Olympic flag consists of five interlaced rings representing the five inhabited continents.',
            'difficulty': 'hard',
            'points': 20,
          },
        ]);
      }

      // Entertainment Questions
      final entId = categoryMap['Entertainment'];
      if (entId != null) {
        questionsToInsert.addAll([
          {
            'category_id': entId,
            'question': 'Which actor portrayed Tony Stark / Iron Man in the Marvel Cinematic Universe?',
            'options': ['Chris Evans', 'Robert Downey Jr.', 'Chris Hemsworth', 'Mark Ruffalo'],
            'correct_answer': 'Robert Downey Jr.',
            'explanation': 'Robert Downey Jr. played Iron Man starting in 2008, launching the highly successful MCU franchise.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': entId,
            'question': 'Which South Korean film made history by winning the Best Picture Oscar in 2020?',
            'options': ['Oldboy', 'Parasite', 'The Handmaiden', 'Minari'],
            'correct_answer': 'Parasite',
            'explanation': 'Directed by Bong Joon-ho, Parasite was the first non-English-language film to win the Academy Award for Best Picture.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': entId,
            'question': 'Who was the iconic lead singer of the rock band Queen?',
            'options': ['David Bowie', 'Mick Jagger', 'Freddie Mercury', 'Elton John'],
            'correct_answer': 'Freddie Mercury',
            'explanation': 'Freddie Mercury was the charismatic lead vocalist and songwriter of the legendary British rock band Queen.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': entId,
            'question': 'In Harry Potter, what is the name of Harry\'s pet owl?',
            'options': ['Scabbers', 'Crookshanks', 'Fang', 'Hedwig'],
            'correct_answer': 'Hedwig',
            'explanation': 'Hedwig was Harry\'s snowy owl, given to him as an 11th birthday present by Rubeus Hagrid.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': entId,
            'question': 'What is the highest-grossing movie of all time (unadjusted for inflation)?',
            'options': ['Avengers: Endgame', 'Titanic', 'Avatar', 'Star Wars: The Force Awakens'],
            'correct_answer': 'Avatar',
            'explanation': 'James Cameron\'s Avatar, released in 2009, is the highest-grossing film of all time.',
            'difficulty': 'hard',
            'points': 20,
          },
        ]);
      }

      // General Knowledge Questions
      final gkId = categoryMap['General Knowledge'];
      if (gkId != null) {
        questionsToInsert.addAll([
          {
            'category_id': gkId,
            'question': 'What is the largest country in the world by land area?',
            'options': ['Canada', 'USA', 'China', 'Russia'],
            'correct_answer': 'Russia',
            'explanation': 'Russia is the largest country, covering over 17 million square kilometers (about 11% of Earth\'s total land area).',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': gkId,
            'question': 'Which mammal is known as the King of the Jungle?',
            'options': ['Tiger', 'Lion', 'Elephant', 'Leopard'],
            'correct_answer': 'Lion',
            'explanation': 'The lion is referred to as the "King of the Jungle", though they live in grasslands and savannas.',
            'difficulty': 'easy',
            'points': 10,
          },
          {
            'category_id': gkId,
            'question': 'How many teeth does a typical adult human have?',
            'options': ['28', '30', '32', '34'],
            'correct_answer': '32',
            'explanation': 'A typical adult human has 32 permanent teeth, including wisdom teeth.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': gkId,
            'question': 'What is the currency of Japan?',
            'options': ['Won', 'Yen', 'Yuan', 'Ringgit'],
            'correct_answer': 'Yen',
            'explanation': 'The Japanese Yen is the official currency of Japan.',
            'difficulty': 'medium',
            'points': 15,
          },
          {
            'category_id': gkId,
            'question': 'Which element on the periodic table has the atomic number 1?',
            'options': ['Helium', 'Oxygen', 'Hydrogen', 'Carbon'],
            'correct_answer': 'Hydrogen',
            'explanation': 'Hydrogen is the lightest chemical element and has the atomic number 1.',
            'difficulty': 'hard',
            'points': 20,
          },
        ]);
      }

      await client.from('questions').insert(questionsToInsert);

      // 3. Create Daily Challenge for today
      try {
        final today = DateTime.now().toIso8601String().split('T')[0];
        await client.from('daily_challenges').insert({
          'category_id': scienceId,
          'date': today,
        });
      } catch (e) {
        debugPrint('Error inserting daily challenge during seed: $e');
      }
    } catch (e) {
      debugPrint('Error seeding database: $e');
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
      debugPrint('Error getting questions: $e');
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
      debugPrint('Error saving quiz session: $e');
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
      debugPrint('Error getting quiz sessions: $e');
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
      debugPrint('Error updating user progress: $e');
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
      debugPrint('Error getting user progress: $e');
      return null;
    }
  }

  // ========== LEADERBOARD METHODS ==========
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50, String filter = 'all'}) async {
    try {
      if (filter == 'all') {
        final response = await client
            .from('users')
            .select('id, name, email, total_score, total_quizzes')
            .order('total_score', ascending: false)
            .limit(limit);

        return List<Map<String, dynamic>>.from(response as List);
      }

      final now = DateTime.now();
      final startDate = filter == 'weekly'
          ? now.subtract(const Duration(days: 7))
          : now.subtract(const Duration(days: 30));

      final response = await client
          .from('quiz_sessions')
          .select('score, user_id, users(name, email)')
          .gte('completed_at', startDate.toUtc().toIso8601String());

      final sessions = List<Map<String, dynamic>>.from(response as List);

      final userScores = <String, Map<String, dynamic>>{};
      for (var session in sessions) {
        final userId = session['user_id'] as String?;
        if (userId == null) continue;

        final score = session['score'] as int? ?? 0;
        final userData = session['users'] as Map<String, dynamic>?;
        final userName = userData?['name'] as String? ?? 'Anonymous';
        final userEmail = userData?['email'] as String? ?? '';

        if (userScores.containsKey(userId)) {
          userScores[userId]!['total_score'] = (userScores[userId]!['total_score'] as int) + score;
          userScores[userId]!['total_quizzes'] = (userScores[userId]!['total_quizzes'] as int) + 1;
        } else {
          userScores[userId] = {
            'id': userId,
            'name': userName,
            'email': userEmail,
            'total_score': score,
            'total_quizzes': 1,
          };
        }
      }

      final leaderboardList = userScores.values.toList()
        ..sort((a, b) => (b['total_score'] as int).compareTo(a['total_score'] as int));

      return leaderboardList.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
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
      debugPrint('Error getting daily challenge: $e');
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
      debugPrint('Error inserting sample data: $e');
    }
  }
}
