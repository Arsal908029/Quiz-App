import 'package:flutter/material.dart';
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

    // For testing - prefill with test credentials
    _loginEmailController.text = '';
    _loginPasswordController.text = '';
    _registerEmailController.text = '';
    _registerPasswordController.text = '';
    _registerNameController.text = '';
    _registerConfirmPasswordController.text = '';
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

    try {
      final response = await SupabaseService().signIn(
        _loginEmailController.text.trim(),
        _loginPasswordController.text.trim(),
      );

      if (response.user != null) {
        // Success - navigate to home
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials.';
        });
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Clean up error messages for better UX
      if (errorMessage.contains('Invalid login credentials')) {
        errorMessage =
            'Invalid email or password. Please check your credentials.';
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
        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Account created successfully! Please check your email to verify.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Switch to login tab and clear form
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

      // Clean up error messages for better UX
      if (errorMessage.contains('User already registered')) {
        errorMessage =
            'This email is already registered. Please login instead.';
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
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
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
            child: const Text(
              'Forgot Password?',
              style: TextStyle(color: Color(0xFF6C63FF)),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Login Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _registerEmailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            obscureText: _registerObscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _register(),
          ),

          const SizedBox(height: 24),

          // Register Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Logo/Header
                const SizedBox(height: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.quiz,
                    size: 60,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quiz Master',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Test your knowledge',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),

                const SizedBox(height: 32),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF6C63FF),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[700],
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Register'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tab Bar View
                SingleChildScrollView(
                  child: SizedBox(
                    height: _tabController.index == 0 ? 260 : 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildLoginForm(), _buildRegisterForm()],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Demo Credentials (Remove in production)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Credentials:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: wwwarsalamal11@gmail.com',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Password: Test@123456',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _loginEmailController.text =
                                'wwwarsalamal11@gmail.com';
                            _loginPasswordController.text = 'Test@123456';
                            _tabController.animateTo(0);
                            _errorMessage = '';
                          });
                        },
                        child: const Text(
                          'Use Demo Login',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
