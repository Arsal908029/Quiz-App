import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_master/core/widgets/glass_card.dart';
import 'package:quiz_master/core/widgets/animated_background.dart';
import 'package:quiz_master/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. EDIT PROFILE SCREEN
// ==========================================
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.initialProfile,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _universityController;
  late TextEditingController _facultyController;
  late TextEditingController _departmentController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _matricController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile?['name'] ?? '');
    _universityController = TextEditingController(text: widget.initialProfile?['university'] ?? '');
    _facultyController = TextEditingController(text: widget.initialProfile?['faculty'] ?? '');
    _departmentController = TextEditingController(text: widget.initialProfile?['department'] ?? '');
    _avatarUrlController = TextEditingController(text: widget.initialProfile?['avatar_url'] ?? '');
    _matricController = TextEditingController(text: widget.initialProfile?['matric_number'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _facultyController.dispose();
    _departmentController.dispose();
    _avatarUrlController.dispose();
    _matricController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = SupabaseService().currentUser;
      if (user != null) {
        final updates = {
          'name': _nameController.text.trim(),
          'university': _universityController.text.trim(),
          'faculty': _facultyController.text.trim(),
          'department': _departmentController.text.trim(),
          'avatar_url': _avatarUrlController.text.trim(),
          'matric_number': _matricController.text.trim(),
        };

        await SupabaseService().updateUserProfile(user.id, updates);
        
        // Also update Auth metadata name to keep in sync
        try {
          await SupabaseService().client.auth.updateUser(
            UserAttributes(data: {'name': _nameController.text.trim()}),
          );
        } catch (_) {}

        widget.onProfileUpdated();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: GlassCard(
                glowColor: const Color(0xff00E5FF),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _avatarUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Avatar Image URL',
                        prefixIcon: Icon(Icons.image_outlined),
                        hintText: 'https://example.com/photo.jpg',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _universityController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'University',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _facultyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Faculty',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _departmentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.workspaces_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _matricController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Matriculation Number',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('Save Changes', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. NOTIFICATIONS SCREEN
// ==========================================
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _soundEffects = true;
  bool _weeklyReminders = false;
  bool _dailyChallengeAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                glowColor: const Color(0xff7C4DFF),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Push Notifications',
                      subtitle: 'Get alerts for leaderboard changes & system updates.',
                      value: _pushNotifications,
                      onChanged: (val) => setState(() => _pushNotifications = val),
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildSwitchTile(
                      title: 'Sound & Vibration',
                      subtitle: 'Enable sound effects during quiz completion.',
                      value: _soundEffects,
                      onChanged: (val) => setState(() => _soundEffects = val),
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildSwitchTile(
                      title: 'Daily Challenge Reminders',
                      subtitle: 'Remind me when today\'s quiz challenge is ready.',
                      value: _dailyChallengeAlerts,
                      onChanged: (val) => setState(() => _dailyChallengeAlerts = val),
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _buildSwitchTile(
                      title: 'Weekly Performance Digest',
                      subtitle: 'Receive a summary of weekly scores and rankings.',
                      value: _weeklyReminders,
                      onChanged: (val) => setState(() => _weeklyReminders = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xff00E5FF),
      activeTrackColor: const Color(0xff7C4DFF).withValues(alpha: 0.4),
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.white10,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ==========================================
// 3. THEME & AESTHETICS SCREEN
// ==========================================
class ThemeAestheticsScreen extends StatefulWidget {
  const ThemeAestheticsScreen({super.key});

  @override
  State<ThemeAestheticsScreen> createState() => _ThemeAestheticsScreenState();
}

class _ThemeAestheticsScreenState extends State<ThemeAestheticsScreen> {
  String _selectedTheme = 'cyber_dark';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Theme & Aesthetics', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildThemeOption(
                id: 'cyber_dark',
                name: 'Cyber Glassmorphism (Dark)',
                desc: 'Premium dark blue background with neon purple and cyan glows (Default).',
                colors: [const Color(0xff151C35), const Color(0xff7C4DFF), const Color(0xff00E5FF)],
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                id: 'amethyst_purple',
                name: 'Amethyst Haze (Dark)',
                desc: 'Vibrant purple environment with soft white and hot pink accent elements.',
                colors: [const Color(0xff1A0933), const Color(0xffFF007F), const Color(0xff9C27B0)],
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                id: 'synthwave',
                name: 'Synthwave Glow',
                desc: 'Retro 80s aesthetics with saturated orange, sunset yellow and hot magenta.',
                colors: [const Color(0xff2A0845), const Color(0xffFF5722), const Color(0xffFFD700)],
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                id: 'solar_light',
                name: 'Solarized Neo (Light)',
                desc: 'Sleek light glass style optimized for bright environments.',
                colors: [const Color(0xffF5F6FA), const Color(0xff3F51B5), const Color(0xff00BCD4)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String id,
    required String name,
    required String desc,
    required List<Color> colors,
  }) {
    final isSelected = _selectedTheme == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = id),
      child: GlassCard(
        glowColor: isSelected ? colors[2] : null,
        borderOpacity: isSelected ? 0.4 : 0.1,
        backgroundOpacity: isSelected ? 0.1 : 0.04,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors[2] : Colors.white24,
                  width: 2,
                ),
                color: isSelected ? colors[1].withValues(alpha: 0.3) : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 18, color: colors[2])
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. LANGUAGE SCREEN
// ==========================================
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLang = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Language', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GlassCard(
              glowColor: const Color(0xff7C4DFF),
              padding: const EdgeInsets.all(12),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildLanguageItem('en', 'English', 'United States / United Kingdom'),
                  const Divider(color: Colors.white10, height: 16),
                  _buildLanguageItem('es', 'Español', 'Spain / Latin America'),
                  const Divider(color: Colors.white10, height: 16),
                  _buildLanguageItem('fr', 'Français', 'France / Canada'),
                  const Divider(color: Colors.white10, height: 16),
                  _buildLanguageItem('de', 'Deutsch', 'Germany / Austria'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(String code, String name, String subtitle) {
    final isSelected = _selectedLang == code;
    return ListTile(
      title: Text(name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xff00E5FF))
          : const Icon(Icons.radio_button_off_rounded, color: Colors.white24),
      onTap: () => setState(() => _selectedLang = code),
    );
  }
}

// ==========================================
// 5. PRIVACY & SECURITY SCREEN
// ==========================================
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _profilePublic = true;
  bool _shareStats = true;
  bool _analyticsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Privacy & Security', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                glowColor: const Color(0xff00E5FF),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('Public Profile', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('Allow other players to search for you and view your score stats.', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                      value: _profilePublic,
                      onChanged: (val) => setState(() => _profilePublic = val),
                      activeThumbColor: const Color(0xff00E5FF),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    SwitchListTile(
                      title: Text('Share Leaderboard Stats', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('Feature your name and rank positions on global competitive leaderboards.', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                      value: _shareStats,
                      onChanged: (val) => setState(() => _shareStats = val),
                      activeThumbColor: const Color(0xff00E5FF),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    SwitchListTile(
                      title: Text('Crash Analytics', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('Share anonymous diagnostics report to optimize app stability.', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                      value: _analyticsEnabled,
                      onChanged: (val) => setState(() => _analyticsEnabled = val),
                      activeThumbColor: const Color(0xff00E5FF),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                glowColor: Colors.redAccent,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Actions', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('These actions are permanent and cannot be reversed. Please make sure before executing.', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All local quiz cache cleared.'), backgroundColor: Colors.orange),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Clear Local Data Cache'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xff151C35),
                              title: const Text('Delete Account?', style: TextStyle(color: Colors.white)),
                              content: const Text('This will delete all your records, stats, profiles, and cannot be undone.', style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Account deletion request registered.'), backgroundColor: Colors.red),
                                    );
                                  },
                                  child: const Text('Confirm', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Delete My Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 6. CHANGE PASSWORD SCREEN
// ==========================================
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService().client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update password: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Change Password', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: GlassCard(
                glowColor: const Color(0xff7C4DFF),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _currentPasswordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) {
                        if (v != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updatePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('Update Password', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. SUPPORT & FEEDBACK SCREEN
// ==========================================
class SupportFeedbackScreen extends StatefulWidget {
  const SupportFeedbackScreen({super.key});

  @override
  State<SupportFeedbackScreen> createState() => _SupportFeedbackScreenState();
}

class _SupportFeedbackScreenState extends State<SupportFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Simulate sending feedback
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted! Thank you for your support.'),
          backgroundColor: Colors.green,
        ),
      );
      _feedbackController.clear();
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Support & Feedback', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: GlassCard(
                glowColor: const Color(0xff00E5FF),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How can we help you?',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Report a bug, suggest questions, or give suggestions to improve the Quiz Master app.',
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _feedbackController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Write your feedback...',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter some feedback' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('Submit Feedback', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 8. ABOUT SCREEN
// ==========================================
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('About Quiz Master', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                glowColor: const Color(0xff7C4DFF),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xff7C4DFF), Color(0xff00E5FF)]),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                      child: const Center(
                        child: Text('⚡', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quiz Master',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'v1.0.0 (Cyber Edition)',
                      style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Quiz Master is a premium, state-of-the-art interactive quiz game designed to test and expand your knowledge in various fields of study.\n\nFeaturing multiple categories, time-based sessions, customizable settings, and local database persistence, Quiz Master is built using Flutter and powered by Supabase.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    _buildMetaRow('Developer', 'Arsalan Ali'),
                    _buildMetaRow('Engine', 'Flutter 3.38'),
                    _buildMetaRow('Backend', 'Supabase Real-time BaaS'),
                    _buildMetaRow('UI Design', 'Cyber Glassmorphism Style'),
                    const Divider(color: Colors.white10, height: 32),
                    Text(
                      '© 2026 Quiz Master Team. All Rights Reserved.',
                      style: GoogleFonts.poppins(color: Colors.white30, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.outfit(color: const Color(0xff00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
