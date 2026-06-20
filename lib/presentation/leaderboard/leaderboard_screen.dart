import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_master/core/widgets/glass_card.dart';
import 'package:quiz_master/data/services/supabase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool isActive;
  const LeaderboardScreen({super.key, this.isActive = false});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, weekly, monthly

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void didUpdateWidget(LeaderboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadLeaderboard();
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final leaderboard = await SupabaseService().getLeaderboard(filter: _filter);
      if (mounted) {
        setState(() {
          _leaderboard = leaderboard;
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
    // Separate top 3 podium entries from the rest
    final podium = _leaderboard.take(3).toList();
    final listEntries = _leaderboard.skip(3).toList();

    return Scaffold(
      backgroundColor: Colors.transparent, // Translucent background
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Hidden back button
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff00E5FF)))
          : Column(
              children: [
                // Filter Tabs (Capsules)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildFilterTab('All Time', 'all')),
                        Expanded(child: _buildFilterTab('Weekly', 'weekly')),
                        Expanded(child: _buildFilterTab('Monthly', 'monthly')),
                      ],
                    ),
                  ),
                ),

                // Top 3 Podium
                if (podium.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildPodium(podium),
                  ),
                  const SizedBox(height: 16),
                ],

                // Leaderboard List (Rank 4+)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110), // Padding for curved nav bar
                    itemCount: listEntries.length,
                    itemBuilder: (context, index) {
                      final user = listEntries[index];
                      final rank = index + 4;
                      return _buildLeaderboardItem(user, rank);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterTab(String title, String value) {
    final isSelected = _filter == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = value;
        });
        _loadLeaderboard();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
                )
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // Beautiful visual podium layout for first 3 users
  Widget _buildPodium(List<Map<String, dynamic>> podium) {
    // Podium order layout: 2nd (left), 1st (center), 3rd (right)
    Map<String, dynamic>? first = podium.isNotEmpty ? podium[0] : null;
    Map<String, dynamic>? second = podium.length > 1 ? podium[1] : null;
    Map<String, dynamic>? third = podium.length > 2 ? podium[2] : null;

    return GlassCard(
      glowColor: const Color(0xff7C4DFF),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      borderRadius: 24,
      backgroundOpacity: 0.08,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 2nd Place Column
          if (second != null)
            _buildPodiumColumn(second, 2, const Color(0xffC0C0C0), 110.0),
          
          // 1st Place Column
          if (first != null)
            _buildPodiumColumn(first, 1, const Color(0xffFFD700), 140.0),
          
          // 3rd Place Column
          if (third != null)
            _buildPodiumColumn(third, 3, const Color(0xffCD7F32), 95.0),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(Map<String, dynamic> user, int rank, Color medalColor, double barHeight) {
    final name = user['name'] as String? ?? 'Anonymous';
    final score = user['total_score'] as int? ?? 0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Trophy/Rank Avatar
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: rank == 1 ? 64 : 50,
              height: rank == 1 ? 64 : 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    medalColor.withOpacity(0.4),
                    medalColor.withOpacity(0.1),
                  ],
                ),
                border: Border.all(color: medalColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: medalColor.withOpacity(0.25),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  rank == 1 ? '👑' : (rank == 2 ? '🥈' : '🥉'),
                  style: TextStyle(fontSize: rank == 1 ? 26 : 20),
                ),
              ),
            ),
            
            // Rank badge overlay
            Positioned(
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: medalColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#$rank',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Name
        SizedBox(
          width: 80,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Score
        Text(
          '$score',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: const Color(0xff00E5FF),
            fontSize: 12,
          ),
        ),
        
        const SizedBox(height: 8),

        // Visual podium block
        Container(
          width: 60,
          height: barHeight * 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                medalColor.withOpacity(0.35),
                medalColor.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              top: BorderSide(color: medalColor.withOpacity(0.5), width: 1.5),
              left: BorderSide(color: medalColor.withOpacity(0.2), width: 1),
              right: BorderSide(color: medalColor.withOpacity(0.2), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user, int rank) {
    final name = user['name'] as String? ?? 'Anonymous';
    final email = user['email'] as String? ?? '';
    final score = user['total_score'] as int? ?? 0;
    final quizzes = user['total_quizzes'] as int? ?? 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        backgroundOpacity: 0.04,
        child: Row(
          children: [
            // Rank Number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 14),
            
            // User Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.emoji_events_rounded,
                        value: '$score pts',
                        color: Colors.amberAccent,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        icon: Icons.quiz_rounded,
                        value: '$quizzes quizzes',
                        color: const Color(0xff00E5FF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Score Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xff7C4DFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xff7C4DFF).withOpacity(0.25)),
              ),
              child: Text(
                '$score pts',
                style: GoogleFonts.outfit(
                  color: const Color(0xff00E5FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}