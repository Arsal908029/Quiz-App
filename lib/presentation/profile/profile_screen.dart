import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_master/core/widgets/glass_card.dart';
import 'package:quiz_master/data/services/supabase_service.dart';
import 'package:quiz_master/presentation/profile/settings_screens.dart';

class ProfileScreen extends StatefulWidget {
  final bool isActive;
  const ProfileScreen({super.key, this.isActive = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _recentSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final user = SupabaseService().currentUser;
      if (user != null) {
        final profile = await SupabaseService().getUserProfile(user.id);
        final sessions = await SupabaseService().getUserQuizSessions(user.id);
        
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _recentSessions = sessions;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService().signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff00E5FF)),
        ),
      );
    }

    final name = _userProfile?['name'] as String? ?? 'Quiz Master';
    final email = _userProfile?['email'] as String? ?? '';
    final totalScore = _userProfile?['total_score'] as int? ?? 0;
    final totalQuizzes = _userProfile?['total_quizzes'] as int? ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow animated background to show through
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Hidden back button
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xff00E5FF),
        backgroundColor: const Color(0xff151C35),
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), // Padding for curved nav bar
          child: Column(
            children: [
              // Profile Header Card
              GlassCard(
                glowColor: const Color(0xff7C4DFF),
                padding: const EdgeInsets.all(20),
                backgroundOpacity: 0.08,
                child: Row(
                  children: [
                    // Profile letter avatar with neon border
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
                        ),
                        border: Border.all(color: Colors.white70, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff7C4DFF).withValues(alpha: 0.3),
                            blurRadius: 12,
                          )
                        ],
                      ),
                      child: _userProfile?['avatar_url'] != null && (_userProfile?['avatar_url'] as String).isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: Image.network(
                                _userProfile!['avatar_url'] as String,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'Q',
                                    style: GoogleFonts.outfit(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'Q',
                                style: GoogleFonts.outfit(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildStatChip(
                                icon: Icons.emoji_events_rounded,
                                value: totalScore.toString(),
                                label: 'pts',
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              _buildStatChip(
                                icon: Icons.quiz_rounded,
                                value: totalQuizzes.toString(),
                                label: 'quizzes',
                                color: const Color(0xff00E5FF),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats Overview Row
              GlassCard(
                glowColor: const Color(0xff00E5FF),
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundOpacity: 0.05,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      title: 'Accuracy',
                      value: '${_calculateAccuracy()}%',
                      icon: Icons.trending_up_rounded,
                      color: Colors.greenAccent,
                    ),
                    _buildStatItem(
                      title: 'Avg. Score',
                      value: '${_calculateAverageScore()}',
                      icon: Icons.star_rounded,
                      color: Colors.amberAccent,
                    ),
                    _buildStatItem(
                      title: 'Best Score',
                      value: '${_calculateBestScore()}',
                      icon: Icons.leaderboard_rounded,
                      color: const Color(0xff7C4DFF),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildAcademicInfoCard(),

              // Settings Section
              _buildSection(
                title: 'Settings',
                children: [
                  _buildSettingItem(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.palette_rounded,
                    title: 'Theme & Aesthetics',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ThemeAestheticsScreen()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LanguageScreen()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy & Security',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Recent Activity Section
              _buildSection(
                title: 'Recent Activity',
                children: _recentSessions.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 48,
                                color: Colors.white30,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No recent activity',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Complete quizzes to see your activity here!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      ]
                    : _recentSessions.take(4).map((session) {
                        return _buildActivityItem(session);
                      }).toList(),
              ),

              const SizedBox(height: 20),

              // Account Actions
              _buildSection(
                title: 'Account Management',
                children: [
                  _buildSettingItem(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile Info',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          initialProfile: _userProfile,
                          onProfileUpdated: _loadUserData,
                        ),
                      ),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.security_rounded,
                    title: 'Change Account Password',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.help_rounded,
                    title: 'Support & Feedback',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportFeedbackScreen()),
                    ),
                  ),
                  _buildSettingItem(
                    icon: Icons.info_rounded,
                    title: 'About Quiz Master',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // App Version text
              Text(
                'Quiz Master v1.0.0 • Cyber Edition',
                style: GoogleFonts.poppins(
                  color: Colors.white30,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero, // list items will have their own padding
          borderRadius: 20,
          backgroundOpacity: 0.04,
          child: Column(
            children: children
                .map((child) => Column(
                      children: [
                        child,
                        if (child != children.last)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.white10,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xff7C4DFF),
        size: 20,
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white24,
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> session) {
    final category = session['categories']?['name'] ?? 'General';
    final score = session['score'] ?? 0;
    final date = DateTime.parse(session['completed_at'] as String);
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xff00E5FF).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.quiz_rounded,
          color: Color(0xff00E5FF),
          size: 18,
        ),
      ),
      title: Text(
        category,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        'Score: $score points',
        style: GoogleFonts.poppins(
          color: Colors.white60,
          fontSize: 11,
        ),
      ),
      trailing: Text(
        formattedDate,
        style: GoogleFonts.poppins(
          color: Colors.white30,
          fontSize: 10,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  int _calculateAccuracy() {
    if (_recentSessions.isEmpty) return 0;
    int totalQuestions = 0;
    int correctAnswers = 0;
    
    for (var session in _recentSessions) {
      totalQuestions += session['total_questions'] as int? ?? 10;
      correctAnswers += session['correct_answers'] as int? ?? 0;
    }
    
    if (totalQuestions == 0) return 0;
    return ((correctAnswers / totalQuestions) * 100).round();
  }

  int _calculateAverageScore() {
    if (_recentSessions.isEmpty) return 0;
    int totalScore = 0;
    
    for (var session in _recentSessions) {
      totalScore += session['score'] as int? ?? 0;
    }
    
    return (totalScore / _recentSessions.length).round();
  }

  int _calculateBestScore() {
    if (_recentSessions.isEmpty) return 0;
    int bestScore = 0;
    
    for (var session in _recentSessions) {
      final score = session['score'] as int? ?? 0;
      if (score > bestScore) {
        bestScore = score;
      }
    }
    
    return bestScore;
  }

  Widget _buildAcademicInfoCard() {
    final university = _userProfile?['university'] as String?;
    final faculty = _userProfile?['faculty'] as String?;
    final department = _userProfile?['department'] as String?;
    final matricNumber = _userProfile?['matric_number'] as String?;

    if (university == null && faculty == null && department == null && matricNumber == null) {
      return const SizedBox.shrink(); // Hide if not a student account
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            'Academic Profile',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        GlassCard(
          glowColor: const Color(0xff7C4DFF),
          padding: const EdgeInsets.all(20),
          backgroundOpacity: 0.05,
          child: Column(
            children: [
              if (university != null)
                _buildInfoRow(Icons.school_rounded, 'University', university),
              if (faculty != null) ...[
                const Divider(color: Colors.white10, height: 16),
                _buildInfoRow(Icons.account_balance_rounded, 'Faculty', faculty),
              ],
              if (department != null) ...[
                const Divider(color: Colors.white10, height: 16),
                _buildInfoRow(Icons.workspaces_rounded, 'Department', department),
              ],
              if (matricNumber != null) ...[
                const Divider(color: Colors.white10, height: 16),
                _buildInfoRow(Icons.badge_rounded, 'Matric No.', matricNumber),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xff00E5FF)),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}