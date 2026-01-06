import 'package:flutter/material.dart';
import 'package:quiz_master/data/services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = SupabaseService().currentUser;
      if (user != null) {
        final profile = await SupabaseService().getUserProfile(user.id);
        final sessions = await SupabaseService().getUserQuizSessions(user.id);
        
        setState(() {
          _userProfile = profile;
          _recentSessions = sessions;
        });
      }
    } catch (e) {
      // Handle error appropriately
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService().signOut();
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      // Show error message
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final name = _userProfile?['name'] as String? ?? 'Quiz Master';
    final email = _userProfile?['email'] as String? ?? '';
    final totalScore = _userProfile?['total_score'] as int? ?? 0;
    final totalQuizzes = _userProfile?['total_quizzes'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildStatChip(
                                context: context,
                                icon: Icons.emoji_events_rounded,
                                value: totalScore.toString(),
                                label: 'Points',
                              ),
                              const SizedBox(width: 12),
                              _buildStatChip(
                                context: context,
                                icon: Icons.quiz_rounded,
                                value: totalQuizzes.toString(),
                                label: 'Quizzes',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats Overview
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context: context,
                            title: 'Accuracy',
                            value: '${_calculateAccuracy()}%',
                            icon: Icons.trending_up_rounded,
                            color: Colors.green,
                          ),
                          _buildStatItem(
                            context: context,
                            title: 'Avg. Score',
                            value: '${_calculateAverageScore()}',
                            icon: Icons.star_rounded,
                            color: Colors.amber,
                          ),
                          _buildStatItem(
                            context: context,
                            title: 'Best Score',
                            value: '${_calculateBestScore()}',
                            icon: Icons.leaderboard_rounded,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Settings Section
              _buildSection(
                context: context,
                title: 'Settings',
                children: [
                  _buildSettingItem(
                    context: context,
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.palette_rounded,
                    title: 'Theme',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.language_rounded,
                    title: 'Language',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Activity
              _buildSection(
                context: context,
                title: 'Recent Activity',
                children: _recentSessions.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history_rounded,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recent activity',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete quizzes to see your activity here!',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        )
                      ]
                    : _recentSessions.take(5).map((session) {
                        return _buildActivityItem(context, session);
                      }).toList(),
              ),

              const SizedBox(height: 24),

              // Account Actions
              _buildSection(
                context: context,
                title: 'Account',
                children: [
                  _buildSettingItem(
                    context: context,
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.security_rounded,
                    title: 'Change Password',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.help_rounded,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.info_rounded,
                    title: 'About App',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // App Version
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Quiz Master v1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
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
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: children
                .map((child) => Column(
                      children: [
                        child,
                        if (child != children.last)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Theme.of(context).dividerColor,
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Map<String, dynamic> session) {
    final category = session['categories']?['name'] ?? 'General';
    final score = session['score'] ?? 0;
    final date = DateTime.parse(session['completed_at'] as String);
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.quiz_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        category,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        'Score: $score points',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Text(
        formattedDate,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          fontSize: 12,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  // Helper methods for calculations
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
}