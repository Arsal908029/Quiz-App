import 'package:flutter/material.dart';
import 'package:quiz_master/data/services/supabase_service.dart';
import 'package:quiz_master/presentation/quiz/quiz_screen.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  Map<String, dynamic>? _dailyChallenge;
  bool _isLoading = true;
  final bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadDailyChallenge();
  }

  Future<void> _loadDailyChallenge() async {
    try {
      final challenge = await SupabaseService().getDailyChallenge();
      setState(() {
        _dailyChallenge = challenge;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Daily Challenge'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_dailyChallenge == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Daily Challenge'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Challenge Today',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Check back tomorrow for a new daily challenge!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final category = _dailyChallenge!['categories'] as Map<String, dynamic>?;
    final categoryName = category?['name'] as String? ?? 'Daily Challenge';
    final categoryColor = category?['color'] as String? ?? '#6C63FF';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenge'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Challenge Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(int.parse(categoryColor.replaceAll('#', '0xFF'))),
                      Color(int.parse(categoryColor.replaceAll('#', '0xFF')))
                          .withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(int.parse(categoryColor.replaceAll('#', '0xFF')))
                          .withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.today, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'TODAY\'S CHALLENGE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.star, color: Colors.white, size: 24),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Complete today\'s special quiz to earn bonus rewards!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Challenge Details
              const Text(
                'Challenge Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildDetailItem(
                icon: Icons.question_answer,
                title: '10 Questions',
                subtitle: 'Mixed difficulty levels',
              ),
              _buildDetailItem(
                icon: Icons.timer,
                title: '15 Minute Limit',
                subtitle: 'Complete before time runs out',
              ),
              _buildDetailItem(
                icon: Icons.emoji_events,
                title: 'Bonus Rewards',
                subtitle: 'Extra points for perfect score',
              ),

              const SizedBox(height: 30),

              // Rules
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Rules & Rewards',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• Complete all 10 questions within 15 minutes\n'
                      '• Earn 10 points for each correct answer\n'
                      '• +50 bonus points for perfect score\n'
                      '• Daily challenge resets at midnight\n'
                      '• Your score will be added to leaderboard',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCompleted
                      ? null
                      : () {
                          // Navigate to quiz screen with daily challenge questions
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(
                                categoryId: 'daily-challenge',
                                categoryName: 'Daily Challenge',
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isCompleted
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Completed Today',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Start Challenge',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}