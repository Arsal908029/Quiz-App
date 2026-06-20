import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:quiz_master/core/widgets/animated_background.dart';
import 'package:quiz_master/core/widgets/glass_card.dart';
import 'package:quiz_master/presentation/quiz/quiz_screen.dart';
import 'package:quiz_master/data/services/supabase_service.dart';

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
      if (mounted) {
        setState(() {
          _dailyChallenge = challenge;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: PremiumBackgroundWrapper(
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xff00E5FF)),
          ),
        ),
      );
    }

    if (_dailyChallenge == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Daily Challenge', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          centerTitle: true,
        ),
        body: PremiumBackgroundWrapper(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                glowColor: Colors.white24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 64,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Challenge Today',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Check back tomorrow for a new daily challenge!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white54),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back to Home'),
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

    final category = _dailyChallenge!['categories'] as Map<String, dynamic>?;
    final categoryName = category?['name'] as String? ?? 'Daily Challenge';
    final categoryColorStr = category?['color'] as String? ?? '#7C4DFF';
    final categoryColor = Color(int.parse(categoryColorStr.replaceAll('#', '0xFF')));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Daily Challenge', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Challenge Header Card
                GlassCard(
                  glowColor: categoryColor,
                  padding: const EdgeInsets.all(24),
                  backgroundOpacity: 0.1,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.today_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  'TODAY\'S CHALLENGE',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Daily challenge graphic (using calendar GIF)
                      SizedBox(
                        height: 120,
                        child: Lottie.network(
                          'https://fonts.gstatic.com/s/i/short-term/release/googlegifs/calendar/v4/medium.gif', // Safe Google hosting for calendar icon animation
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Text('📅', style: TextStyle(fontSize: 60)));
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        categoryName,
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete today\'s special quiz to earn bonus rewards!',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Challenge Details Header
                Text(
                  'Challenge Details',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                _buildDetailItem(
                  icon: Icons.question_answer_rounded,
                  title: '10 Questions',
                  subtitle: 'Mixed difficulty levels',
                  color: const Color(0xff00E5FF),
                ),
                _buildDetailItem(
                  icon: Icons.timer_outlined,
                  title: '15 Minute Limit',
                  subtitle: 'Complete before time runs out',
                  color: const Color(0xff7C4DFF),
                ),
                _buildDetailItem(
                  icon: Icons.emoji_events_rounded,
                  title: 'Bonus Rewards',
                  subtitle: 'Extra points for perfect score',
                  color: Colors.amber,
                ),

                const SizedBox(height: 24),

                // Rules
                GlassCard(
                  glowColor: const Color(0xff00E5FF),
                  borderOpacity: 0.2,
                  backgroundOpacity: 0.04,
                  padding: const EdgeInsets.all(18),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xff00E5FF), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Rules & Rewards',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff00E5FF),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Complete all 10 questions within 15 minutes\n'
                        '• Earn 10 points for each correct answer\n'
                        '• +50 bonus points for perfect score\n'
                        '• Daily challenge resets at midnight\n'
                        '• Your score will be added to leaderboard',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Start Button
                Container(
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
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isCompleted
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuizScreen(
                                  categoryId: 'daily-challenge',
                                  categoryName: 'Daily Challenge',
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isCompleted
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 22, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Completed Today',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 22, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Start Challenge',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        backgroundOpacity: 0.04,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}