import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_master/core/widgets/animated_background.dart';
import 'package:quiz_master/core/widgets/glass_card.dart';
import 'package:quiz_master/data/services/supabase_service.dart';
import 'package:quiz_master/presentation/categories/categories_screen.dart';
import 'package:quiz_master/presentation/quiz/daily_challenge_screen.dart';
import 'package:quiz_master/presentation/profile/profile_screen.dart';
import 'package:quiz_master/presentation/leaderboard/leaderboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late User? _currentUser;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUser = SupabaseService().currentUser;
    if (_currentUser != null) {
      await SupabaseService().getUserProfile(_currentUser!.id);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeContent(isActive: _selectedIndex == 0),
      const CategoriesScreen(),
      LeaderboardScreen(isActive: _selectedIndex == 2),
      ProfileScreen(isActive: _selectedIndex == 3),
    ];

    return Scaffold(
      extendBody: true, // Extends the body under the bottom navigation bar
      body: PremiumBackgroundWrapper(
        child: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff7C4DFF).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xff151C35).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavBarItem(0, Icons.grid_view_rounded, 'Home'),
                _buildNavBarItem(1, Icons.category_rounded, 'Categories'),
                _buildNavBarItem(2, Icons.emoji_events_rounded, 'Leaderboard'),
                _buildNavBarItem(3, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xff7C4DFF).withValues(alpha: 0.25) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xff00E5FF) : Colors.white54,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? const Color(0xff00E5FF) : Colors.white30,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final bool isActive;
  const HomeContent({super.key, this.isActive = false});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _dailyChallenge;
  List<Map<String, dynamic>> _recentSessions = [];
  bool _isLoading = true;
  int _rank = 1;
  double _accuracy = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final challenge = await SupabaseService().getDailyChallenge();
      final user = SupabaseService().currentUser;
      
      if (user != null) {
        final profile = await SupabaseService().getUserProfile(user.id);
        final sessions = await SupabaseService().getUserQuizSessions(user.id);
        
        // Calculate accuracy
        int totalQuestions = 0;
        int correctAnswers = 0;
        for (var session in sessions) {
          totalQuestions += session['total_questions'] as int? ?? 10;
          correctAnswers += session['correct_answers'] as int? ?? 0;
        }
        final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

        // Calculate rank from leaderboard
        int rank = 1;
        try {
          final leaderboard = await SupabaseService().getLeaderboard();
          for (int i = 0; i < leaderboard.length; i++) {
            if (leaderboard[i]['id'] == user.id) {
              rank = i + 1;
              break;
            }
          }
        } catch (e) {
          debugPrint('Error loading rank: $e');
        }

        if (mounted) {
          setState(() {
            _userProfile = profile;
            _dailyChallenge = challenge;
            _recentSessions = sessions;
            _accuracy = accuracy;
            _rank = rank;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, // Don't clip bottom to allow content under the nav bar
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff00E5FF)))
          : RefreshIndicator(
              color: const Color(0xff00E5FF),
              backgroundColor: const Color(0xff151C35),
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 110.0), // Padding at bottom for floating nav bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    _buildWelcomeHeader(),
                    
                    const SizedBox(height: 28),
                    
                    // Daily Challenge Card
                    if (_dailyChallenge != null)
                      _buildDailyChallengeCard(),
                    
                    const SizedBox(height: 28),
                    
                    // Quick Stats
                    _buildQuickStats(),
                    
                    const SizedBox(height: 28),
                    
                    // Recent Activity
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
    final user = SupabaseService().currentUser;
    final name = _userProfile?['name'] as String? ?? user?.email?.split('@').first ?? 'Quiz Master';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ready to test your knowledge today?',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
        
        // Small animated logo badge or avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
            ),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: const Center(
            child: Text(
              '⚡',
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChallengeCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DailyChallengeScreen(),
          ),
        );
      },
      child: GlassCard(
        glowColor: const Color(0xff00E5FF),
        padding: const EdgeInsets.all(22),
        backgroundOpacity: 0.1,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff00E5FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xff00E5FF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'DAILY CHALLENGE',
                      style: GoogleFonts.outfit(
                        color: const Color(0xff00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '10 Questions • 15 Minutes',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete today\'s challenge to earn bonus points!',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xff00E5FF), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '+100 Bonus Points',
                        style: GoogleFonts.outfit(
                          color: const Color(0xff00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Neon play button circle
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E5FF).withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalScore = _userProfile?['total_score'] as int? ?? 0;
    final totalQuizzes = _userProfile?['total_quizzes'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.45,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              title: 'Total Score',
              value: totalScore.toString(),
              icon: Icons.emoji_events_rounded,
              color: Colors.amber,
            ),
            _buildStatCard(
              title: 'Quizzes Taken',
              value: totalQuizzes.toString(),
              icon: Icons.quiz_rounded,
              color: const Color(0xff00E5FF),
            ),
            _buildStatCard(
              title: 'Accuracy',
              value: '${_accuracy.round()}%',
              icon: Icons.trending_up_rounded,
              color: Colors.greenAccent,
            ),
            _buildStatCard(
              title: 'Rank',
              value: '#$_rank',
              icon: Icons.leaderboard_rounded,
              color: const Color(0xff7C4DFF),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      glowColor: color,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: _loadData,
              child: Text(
                'View All',
                style: GoogleFonts.outfit(
                  color: const Color(0xff00E5FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentSessions.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(32),
            backgroundOpacity: 0.04,
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: Colors.white30,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent activity',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete a quiz to see your activity here!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentSessions.take(3).map((session) {
            return _buildActivityItem(session);
          }),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> session) {
    final category = session['categories']?['name'] ?? 'General';
    final score = session['score'] ?? 0;
    final date = DateTime.parse(session['completed_at'] as String);
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        backgroundOpacity: 0.05,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xff7C4DFF).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xff7C4DFF).withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: Color(0xff7C4DFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Score: $score points',
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formattedDate,
              style: GoogleFonts.poppins(
                color: Colors.white30,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}