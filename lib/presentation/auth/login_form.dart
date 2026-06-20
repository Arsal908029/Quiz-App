import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quiz_master/data/services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // For testing - prefill with test credentials
    _emailController.text = 'wwwarsalamal11@gmail.com';
    _passwordController.text = 'password';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        // Login
        try {
          final response = await SupabaseService().signIn(email, password);

          if (response.user != null) {
            // Success - navigate to home
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            setState(() {
              _errorMessage = 'Login failed. Please check your credentials.';
            });
          }
        } on AuthException catch (e) {
          String errorMessage = e.message;

          // Handle specific auth errors
          if (e.statusCode == 'invalid_credentials' ||
              e.message.contains('Invalid login credentials')) {
            if (email == 'wwwarsalamal11@gmail.com' && password == 'password') {
              try {
                // Attempt automatic registration for demo credentials
                await SupabaseService().signUp(
                  'wwwarsalamal11@gmail.com',
                  'password',
                  'Demo User',
                );
                // Sign in again
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
              errorMessage =
                  'Invalid email or password. Please check your credentials.';
            }
          } else if (e.message.contains('Email not confirmed')) {
            errorMessage =
                'Email not verified. Please check your inbox for a verification email.';
          } else if (e.message.contains('User not found') ||
              e.message.contains('Invalid user')) {
            errorMessage =
                'This email is not registered. Please create an account first.';
          }

          setState(() {
            _errorMessage = errorMessage;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Register
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          setState(() {
            _errorMessage = 'Please enter your name';
            _isLoading = false;
          });
          return;
        }

        try {
          final response = await SupabaseService().signUp(
            email,
            password,
            name,
          );

          if (response.user != null) {
            // Show success message and auto-login or switch to login
            if (!mounted) return;

            // Try to auto-login after registration
            try {
              await SupabaseService().signIn(email, password);
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/home');
            } catch (loginE) {
              // If auto-login fails, show message and switch to login screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Account created successfully! Please verify your email and login.',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );

              setState(() {
                _isLogin = true;
                _errorMessage = '';
                _nameController.clear();
              });
            }
          } else {
            setState(() {
              _errorMessage = 'Registration failed. Please try again.';
            });
          }
        } on AuthException catch (e) {
          String errorMessage = e.message;

          // Handle specific registration errors
          if (e.message.contains('already registered') ||
              e.message.contains('User already exists')) {
            errorMessage =
                'This email is already registered. Please login instead.';
          } else if (e.message.contains('Password should be at least')) {
            errorMessage = 'Password must be at least 6 characters long.';
          } else if (e.message.contains('Invalid email')) {
            errorMessage = 'Please enter a valid email address.';
          } else if (e.message.contains('password')) {
            errorMessage =
                'Password does not meet requirements. Use at least 6 characters.';
          }

          setState(() {
            _errorMessage = errorMessage;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Clean up generic error messages
      if (errorMessage.contains('Network')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage =
            'Request timed out. Please check your connection and try again.';
      } else {
        errorMessage = 'An error occurred: $errorMessage';
      }

      setState(() {
        _errorMessage = errorMessage;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Logo and Title
              const SizedBox(height: 60),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.quiz, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Quiz Master',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test your knowledge',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // Toggle between Login and Register
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (!_isLogin) {
                            setState(() {
                              _isLogin = true;
                              _errorMessage = '';
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _isLogin
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Login',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isLogin
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_isLogin) {
                            setState(() {
                              _isLogin = false;
                              _errorMessage = '';
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: !_isLogin
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Register',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isLogin
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Auth Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name Field (only for registration)
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (!_isLogin && (value == null || value.isEmpty)) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: _isLogin
                            ? 'Enter your password'
                            : 'Create a password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: !_isLogin
                          ? TextInputAction.next
                          : TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    // Confirm Password Field (only for registration)
                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        validator: !_isLogin
                            ? (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              }
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Forgot Password (only for login)
                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot-password');
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),

                    // Error Message Display
                    if (_errorMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
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

                    if (_errorMessage.isNotEmpty) const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _isLogin ? 'Login' : 'Create Account',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Toggle Text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? "Don't have an account?"
                              : "Already have an account?",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = '';
                              if (_isLogin) {
                                _nameController.clear();
                              }
                            });
                          },
                          child: Text(
                            _isLogin ? 'Register' : 'Login',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Debug Section (Remove in production)
                    const SizedBox(height: 40),
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
                            'Debug Information:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${_emailController.text}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Password Length: ${_passwordController.text.length} chars',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () {
                              // Test credentials
                              _emailController.text = 'test@example.com';
                              _passwordController.text = 'password';
                              _nameController.text = 'Test User';
                              _submit();
                            },
                            child: const Text(
                              'Try with test credentials',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
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
