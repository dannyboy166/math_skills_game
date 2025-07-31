// lib/screens/auth/register_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:number_ninja/screens/home_screen.dart';
import 'dart:io' show Platform;

import 'package:number_ninja/services/auth_service.dart';
import 'package:number_ninja/services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Age dropdown instead of text field
  String? _selectedAge;

  bool _isLoading = false;
  bool _isSocialLoading = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Create Firebase Authentication account
      final result = await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      // Create user profile
      try {
        final age = _getAgeFromSelection(_selectedAge) ?? 8;
        await _userService.createUserProfile(
          result.user!,
          displayName: _nameController.text.trim(),
          age: age,
        );
      } catch (profileError) {
        // If profile creation fails, log the error but don't fail the registration
        print("Error creating user profile: $profileError");
        // The user is still created, so we can continue
      }

      // Registration successful, show success message
      if (mounted) {
        // Show a fun success animation or dialog
        _showSuccessDialog();

        // Briefly delay before navigating to HomeScreen
        Future.delayed(Duration(seconds: 2), () {
          // Navigate to home screen instead of going back to login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSocialLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _authService.signInWithGoogle();
      
      if (result != null && result.user != null) {
        // Check if user profile already exists
        final existingProfile = await _userService.getUserProfileData(result.user!.uid);
        
        if (existingProfile == null) {
          // New user - show age selection dialog
          final selectedAge = await _showAgeSelectionDialog();
          if (selectedAge == null) {
            // User cancelled age selection, don't proceed
            return;
          }
          
          // Create user profile for new user
          try {
            await _userService.createUserProfile(
              result.user!,
              displayName: result.user!.displayName ?? 'Player',
              age: _getAgeFromSelection(selectedAge) ?? 8,
            );
          } catch (profileError) {
            print("Error creating user profile: $profileError");
          }
        }
        // Existing user - skip age dialog and proceed directly

        if (mounted) {
          _showSuccessDialog();
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isSocialLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _authService.signInWithApple();
      
      if (result != null && result.user != null) {
        // Check if user profile already exists
        final existingProfile = await _userService.getUserProfileData(result.user!.uid);
        
        if (existingProfile == null) {
          // New user - show age selection dialog
          final selectedAge = await _showAgeSelectionDialog();
          if (selectedAge == null) {
            // User cancelled age selection, don't proceed
            return;
          }
          
          // Create user profile for new user
          try {
            await _userService.createUserProfile(
              result.user!,
              displayName: result.user!.displayName ?? 'Player',
              age: _getAgeFromSelection(selectedAge) ?? 8,
            );
          } catch (profileError) {
            print("Error creating user profile: $profileError");
          }
        }
        // Existing user - skip age dialog and proceed directly

        if (mounted) {
          _showSuccessDialog();
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 70,
                ),
                SizedBox(height: 16),
                Text(
                  'Hooray!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your account has been created successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Get ready for math adventures!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak';
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method';
        case 'sign_in_canceled':
          return 'Sign in was canceled';
        default:
          return 'An error occurred: ${e.message}';
      }
    }
    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back Button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 28,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),

                    SizedBox(height: 20),

                    // App Logo and Title
                    _buildAppLogo(),

                    SizedBox(height: 8),
                    _buildWelcomeText(),
                    SizedBox(height: 32),

                    // Social Sign-In Buttons
                    _buildSocialSignInButtons(),

                    SizedBox(height: 24),

                    // Or divider
                    _buildOrDivider(),

                    SizedBox(height: 24),

                    // Form Fields
                    _buildNameField(),
                    SizedBox(height: 16),

                    _buildAgeField(),
                    SizedBox(height: 16),

                    _buildEmailField(),
                    SizedBox(height: 16),

                    _buildPasswordField(),
                    SizedBox(height: 16),

                    _buildConfirmPasswordField(),
                    SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage.isNotEmpty) _buildErrorMessage(),

                    // Register Button
                    _buildRegisterButton(),

                    SizedBox(height: 16),

                    // Sign In Link
                    _buildSignInLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialSignInButtons() {
    return Column(
      children: [
        // Google Sign In Button
        Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSocialLoading ? null : _signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isSocialLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.google,
                        size: 20,
                        color: Colors.red,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        SizedBox(height: 16),

        // Apple Sign In Button (only show on iOS)
        if (Platform.isIOS)
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSocialLoading ? null : _signInWithApple,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSocialLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.apple,
                          size: 20,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Continue with Apple',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/images/ninja.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Number Ninja',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Join the fun and start learning math!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Name',
          hintText: 'What should we call you?',
          prefixIcon: Icon(
            Icons.person,
            color: Colors.green,
            size: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.green.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.green.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your name';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: 'Email',
          hintText: 'Your email address',
          prefixIcon: Icon(
            Icons.email,
            color: Colors.blue,
            size: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          // Simple email validation
          if (!value.contains('@') || !value.contains('.')) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: 'Create a strong password',
          prefixIcon: Icon(
            Icons.lock,
            color: Colors.purple,
            size: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.purple.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.purple.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.purple, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          hintText: 'Type your password again',
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.purple,
            size: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.purple.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.purple.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.purple, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow.shade600,
          foregroundColor: Colors.blue.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue.shade900,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Helper method to convert age selection to integer
  int? _getAgeFromSelection(String? ageSelection) {
    if (ageSelection == null) return null;
    if (ageSelection == '11+') return 11;
    return int.tryParse(ageSelection);
  }

  // Show age selection dialog for social sign-in users
  Future<String?> _showAgeSelectionDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        String? selectedAge;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cake,
                      color: Colors.orange,
                      size: 50,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'How old are you?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This helps us unlock the right math tables for you!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedAge,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintText: 'Select your age',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                        ),
                        items: ['3', '4', '5', '6', '7', '8', '9', '10', '11+']
                            .map((String age) => DropdownMenuItem<String>(
                                  value: age,
                                  child: Text(
                                    age == '11+' ? '11+ years' : '$age years',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedAge = newValue;
                          });
                        },
                        dropdownColor: Colors.white,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(null);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedAge != null ? () {
                              Navigator.of(dialogContext).pop(selectedAge);
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAgeField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedAge,
        decoration: InputDecoration(
          labelText: 'Age',
          hintText: 'How old are you?',
          prefixIcon: Icon(
            Icons.cake,
            color: Colors.orange,
            size: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.orange.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.orange.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.orange, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        items: ['3', '4', '5', '6', '7', '8', '9', '10', '11+']
            .map((String age) => DropdownMenuItem<String>(
                  value: age,
                  child: Text(
                    age == '11+' ? '11+ years' : '$age years',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedAge = newValue;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select your age';
          }
          return null;
        },
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}