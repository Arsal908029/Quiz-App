import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_master/core/widgets/animated_background.dart';
import 'package:quiz_master/core/widgets/animated_logo.dart';
import 'package:quiz_master/core/widgets/glass_card.dart';
import 'package:quiz_master/data/services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _errorMessage = '';

  // Controllers for both forms
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  bool _loginObscurePassword = true;
  bool _registerObscurePassword = true;
  bool _registerObscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    // Prefill login with demo credentials
    _loginEmailController.text = 'wwwarsalamal11@gmail.com';
    _loginPasswordController.text = 'password';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerNameController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmailController.text.isEmpty ||
        _loginPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    try {
      final response = await SupabaseService().signIn(email, password);

      if (response.user != null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials.';
        });
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Invalid login credentials')) {
        if (email == 'wwwarsalamal11@gmail.com' && password == 'password') {
          try {
            // Attempt to automatically register the demo account if it doesn't exist
            await SupabaseService().signUp(
              'wwwarsalamal11@gmail.com',
              'password',
              'Demo User',
            );
            // Sign in again after registration
            final retryResponse = await SupabaseService().signIn(
              'wwwarsalamal11@gmail.com',
              'password',
            );
            if (retryResponse.user != null) {
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/home');
              return;
            }
          } catch (signUpError) {
            final errorMsg = signUpError.toString();
            if (errorMsg.contains('Email not confirmed') || errorMsg.contains('email_not_confirmed')) {
              errorMessage = 'Demo account created! However, email confirmation is enabled in your Supabase project. Please disable "Confirm email" under Auth -> Providers -> Email in your Supabase Dashboard.';
            } else {
              errorMessage = 'Failed to auto-create demo user: $errorMsg';
            }
          }
        } else {
          errorMessage = 'Invalid email or password. Please check your credentials.';
        }
      } else if (errorMessage.contains('Email not confirmed')) {
        errorMessage = 'Please verify your email address before logging in.';
      } else if (errorMessage.contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (errorMessage.contains('Network is unreachable')) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
    if (_registerNameController.text.isEmpty ||
        _registerEmailController.text.isEmpty ||
        _registerPasswordController.text.isEmpty ||
        _registerConfirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (_registerPasswordController.text !=
        _registerConfirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_registerPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await SupabaseService().signUp(
        _registerEmailController.text.trim(),
        _registerPasswordController.text.trim(),
        _registerNameController.text.trim(),
      );

      if (response.user != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please check your email to verify.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        _tabController.animateTo(0);
        setState(() {
          _errorMessage = '';
        });
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('User already registered')) {
        errorMessage = 'This email is already registered. Please login instead.';
      } else if (errorMessage.contains('Password should be at least')) {
        errorMessage = 'Password must be at least 6 characters long.';
      } else if (errorMessage.contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address.';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email Field
        TextFormField(
          controller: _loginEmailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 16),

        // Password Field
        TextFormField(
          controller: _loginPasswordController,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _loginObscurePassword = !_loginObscurePassword;
                });
              },
              icon: Icon(
                _loginObscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          obscureText: _loginObscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _login(),
        ),

        const SizedBox(height: 8),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/forgot-password');
            },
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.outfit(
                color: const Color(0xff00E5FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Login Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff7C4DFF).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Login',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Name Field
          TextFormField(
            controller: _registerNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _registerEmailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _registerPasswordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Create a password (min. 6 characters)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _registerObscurePassword = !_registerObscurePassword;
                  });
                },
                icon: Icon(
                  _registerObscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
            ),
            obscureText: _registerObscurePassword,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // Confirm Password Field
          TextFormField(
            controller: _registerConfirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _registerObscureConfirmPassword =
                        !_registerObscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _registerObscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
            ),
            obscureText: _registerObscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _register(),
          ),

          const SizedBox(height: 24),

          // Register Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff7C4DFF).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Create Account',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formHeight = _tabController.index == 0 ? 270.0 : 420.0;
    
    return Scaffold(
      body: PremiumBackgroundWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  
                  // Animated Logo
                  const AnimatedLogo(size: 90),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Quiz Master',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    'Test your knowledge',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Main Interactive Form wrapped in GlassCard
                  GlassCard(
                    glowColor: const Color(0xff7C4DFF),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tabs selector with glass/cyber styling
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xff7C4DFF), Color(0xff00E5FF)],
                              ),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white38,
                            labelStyle: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            tabs: const [
                              Tab(text: 'Login'),
                              Tab(text: 'Register'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Error Message Display
                        if (_errorMessage.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: GoogleFonts.poppins(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Tab Bar View content
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: formHeight,
                          child: TabBarView(
                            controller: _tabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildLoginForm(),
                              _buildRegisterForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Demo Credentials Glass Card (Remove in production / style premium)
                  GlassCard(
                    glowColor: const Color(0xff00E5FF),
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    backgroundOpacity: 0.05,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xff00E5FF), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Demo Credentials:',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email: wwwarsalamal11@gmail.com',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
                        ),
                        Text(
                          'Password: password',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _loginEmailController.text = 'wwwarsalamal11@gmail.com';
                              _loginPasswordController.text = 'password';
                              _tabController.animateTo(0);
                              _errorMessage = '';
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Use Demo Login Credentials',
                            style: GoogleFonts.outfit(
                              fontSize: 12, 
                              color: const Color(0xff00E5FF),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
