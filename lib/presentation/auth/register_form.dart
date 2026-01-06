import 'package:flutter/material.dart';
import 'package:quiz_master/data/services/supabase_service.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _matricController = TextEditingController(); // Added matric number field
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  String? _selectedFaculty; // Added faculty selection
  String? _selectedDepartment; // Added department selection

  // UI Colors
  final Color _uiPrimaryColor = const Color(0xFF800000); // UI Maroon
  final Color _uiSecondaryColor = const Color(0xFFF0A500); // UI Gold

  // Faculty and Department data (simplified for UI)
  final Map<String, List<String>> _facultyDepartments = {
    'Arts': ['English', 'History', 'Philosophy', 'Linguistics'],
    'Science': ['Chemistry', 'Physics', 'Mathematics', 'Computer Science'],
    'Social Sciences': ['Economics', 'Political Science', 'Sociology', 'Psychology'],
    'Medicine': ['Medicine and Surgery', 'Dentistry', 'Physiotherapy'],
    'Law': ['Law'],
    'Education': ['Adult Education', 'Special Education', 'Educational Management'],
  };

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_selectedFaculty == null || _selectedDepartment == null) {
      setState(() {
        _errorMessage = 'Please select your faculty and department';
      });
      return;
    }

    // Validate matric number format (example: 123456789)
    if (!RegExp(r'^\d{9}$').hasMatch(_matricController.text.trim())) {
      setState(() {
        _errorMessage = 'Please enter a valid 9-digit matric number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Create user profile with additional UI-specific data
      final response = await SupabaseService().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        additionalData: {
          'matric_number': _matricController.text.trim(),
          'faculty': _selectedFaculty!,
          'department': _selectedDepartment!,
          'university': 'University of Ibadan',
        },
      );

      if (response.user != null) {
        // Success - user is automatically logged in after registration
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // UI Logo/Header
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _uiPrimaryColor,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: _uiSecondaryColor, width: 3),
                    ),
                    child: const Center(
                      child: Text(
                        'UI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'University of Ibadan',
                    style: TextStyle(
                      color: _uiPrimaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Student Registration',
                    style: TextStyle(
                      color: _uiPrimaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: _uiPrimaryColor),
                prefixIcon: Icon(Icons.person, color: _uiPrimaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Matric Number Field
            TextFormField(
              controller: _matricController,
              decoration: InputDecoration(
                labelText: 'Matriculation Number',
                labelStyle: TextStyle(color: _uiPrimaryColor),
                prefixIcon: Icon(Icons.badge, color: _uiPrimaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor, width: 2),
                ),
                hintText: 'e.g., 123456789',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your matric number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email Field (using UI email format)
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'University Email',
                labelStyle: TextStyle(color: _uiPrimaryColor),
                prefixIcon: Icon(Icons.email, color: _uiPrimaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor, width: 2),
                ),
                hintText: 'e.g., 123456789@stu.ui.edu.ng',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.endsWith('@stu.ui.edu.ng') && !value.contains('@')) {
                  return 'Please use your university email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Faculty Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedFaculty,
              decoration: InputDecoration(
                labelText: 'Faculty',
                labelStyle: TextStyle(color: _uiPrimaryColor),
                prefixIcon: Icon(Icons.school, color: _uiPrimaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor, width: 2),
                ),
              ),
              items: _facultyDepartments.keys.map((String faculty) {
                return DropdownMenuItem<String>(
                  value: faculty,
                  child: Text(faculty),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedFaculty = value;
                  _selectedDepartment = null; // Reset department when faculty changes
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your faculty';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Department Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartment,
              decoration: InputDecoration(
                labelText: 'Department',
                labelStyle: TextStyle(color: _uiPrimaryColor),
                prefixIcon: Icon(Icons.workspaces, color: _uiPrimaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor, width: 2),
                ),
              ),
              items: _selectedFaculty == null
                  ? []
                  : _facultyDepartments[_selectedFaculty]!.map((String dept) {
                      return DropdownMenuItem<String>(
                        value: dept,
                        child: Text(dept),
                      );
                    }).toList(),
              onChanged: _selectedFaculty == null
                  ? null
                  : (String? value) {
                      setState(() {
                        _selectedDepartment = value;
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your department';
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
                labelStyle: TextStyle(color: _uiPrimaryColor),
                prefixIcon: Icon(Icons.lock, color: _uiPrimaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor, width: 2),
                ),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(color: _uiPrimaryColor),
                prefixIcon: Icon(Icons.lock_outline, color: _uiPrimaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _uiPrimaryColor, width: 2),
                ),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                return null;
              },
            ),

            // Error Message
            if (_errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Register Button with UI colors
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _uiPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: _uiPrimaryColor.withOpacity(0.3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Register as UI Student',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms and Conditions with UI branding
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'By registering, you agree to the '),
                    TextSpan(
                      text: 'University of Ibadan',
                      style: TextStyle(
                        color: _uiPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: '\nStudent Portal '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: _uiPrimaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: _uiPrimaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // University motto
            Text(
              '"Recte Sapere Fons"',
              style: TextStyle(
                color: _uiSecondaryColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _matricController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}