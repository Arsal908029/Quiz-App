import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_master/core/widgets/glass_card.dart';
import 'package:quiz_master/data/services/supabase_service.dart';
import 'package:quiz_master/presentation/quiz/quiz_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final categories = await SupabaseService().getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().contains('does not exist') || e.toString().contains('42P01')
              ? 'Database tables are missing.\nPlease run the SQL setup script in your Supabase SQL Editor.'
              : 'Failed to load categories. Please check your connection or database setup.';
        });
      }
    }
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xff7C4DFF), // Neon Purple
      const Color(0xff00E5FF), // Neon Cyan
      const Color(0xffFF007F), // Neon Pink
      const Color(0xffFFD700), // Neon Yellow/Gold
      const Color(0xff00FF66), // Neon Green
      const Color(0xffFF6200), // Neon Orange
      const Color(0xffFF3B30), // Neon Red
      const Color(0xff007AFF), // Neon Royal Blue
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator(color: Color(0xff00E5FF)));
    } else if (_errorMessage.isNotEmpty) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GlassCard(
            glowColor: Colors.redAccent,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 60,
                ),
                const SizedBox(height: 18),
                Text(
                  'Database Setup Required',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadCategories,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff7C4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_categories.isEmpty) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GlassCard(
            glowColor: const Color(0xff00E5FF),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.category_outlined,
                  color: Color(0xff00E5FF),
                  size: 60,
                ),
                const SizedBox(height: 18),
                Text(
                  'No Categories Found',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your category table is empty. Click below to try seeding categories and questions.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadCategories,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reload & Seed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff7C4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      bodyContent = GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), // Extra bottom padding for floating nav bar
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.88,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category, index);
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow animated background to show through
      appBar: AppBar(
        title: Text(
          'Categories',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide back button since it's on navigation bar
      ),
      body: bodyContent,
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    final name = category['name'] as String? ?? 'Category';
    final description = category['description'] as String? ?? 'Test your knowledge';
    final questionCount = category['question_count'] as int? ?? 0;
    final icon = category['icon'] as String? ?? '🧠';
    final color = _getCategoryColor(index);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              categoryId: category['id'] as String,
              categoryName: name,
            ),
          ),
        );
      },
      child: GlassCard(
        glowColor: color,
        padding: const EdgeInsets.all(16),
        borderRadius: 22,
        backgroundOpacity: 0.04,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.question_answer_rounded,
                  color: color,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '$questionCount questions',
                  style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}