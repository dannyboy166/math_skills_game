// lib/screens/auth/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:number_ninja/screens/auth/register_screen.dart';
import 'package:number_ninja/screens/home_screen.dart';
import 'dart:io' show Platform;

import 'package:number_ninja/services/auth_service.dart';
import 'package:number_ninja/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSocialLoading = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    print("LOGIN DEBUG: LoginScreen initialized");
    // Check if there's a current user when the login screen initializes
    print(
        "LOGIN DEBUG: Current user on init: ${FirebaseAuth.instance.currentUser?.uid ?? 'null'}");

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

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    print(
        "LOGIN DEBUG: Starting email sign-in for: ${_emailController.text.trim()}");
    print(
        "LOGIN DEBUG: Current user before sign-in attempt: ${FirebaseAuth.instance.currentUser?.uid ?? 'null'}");

    try {
      final result = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      print("LOGIN DEBUG: Sign-in call completed");
      print(
          "LOGIN DEBUG: Current user after sign-in: ${FirebaseAuth.instance.currentUser?.uid ?? 'null'}");

      if (mounted && result.user != null) {
        print(
            "LOGIN DEBUG: User is logged in, manually navigating to HomeScreen");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
      } else {
        print(
            "LOGIN DEBUG: Auth state listener should handle navigation automatically");
      }
    } catch (e) {
      print("LOGIN DEBUG: Sign-in failed with error: $e");
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

        print(
            "LOGIN DEBUG: Final check - current user: ${FirebaseAuth.instance.currentUser?.uid ?? 'null'}");
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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
          );
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

  String _getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'This account has been disabled';
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

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController resetEmailController = TextEditingController();
    resetEmailController.text = _emailController.text;
    bool isLoading = false;
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your email address and we will send you a password reset link.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('Cancel'),
                ),
                isLoading
                    ? Container(
                        width: 20,
                        height: 20,
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          if (resetEmailController.text.trim().isEmpty) {
                            setState(() {
                              errorMessage = 'Please enter your email address';
                            });
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = '';
                          });

                          try {
                            await _authService.resetPassword(
                              resetEmailController.text.trim(),
                            );

                            Navigator.of(dialogContext).pop();

                            // Show success message
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Password reset email sent. Please check your inbox.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              if (e is FirebaseAuthException) {
                                if (e.code == 'user-not-found') {
                                  errorMessage =
                                      'No user found with this email';
                                } else if (e.code == 'invalid-email') {
                                  errorMessage = 'Invalid email address';
                                } else {
                                  errorMessage =
                                      'An error occurred: ${e.message}';
                                }
                              } else {
                                errorMessage = 'Failed to send reset email';
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text('Send Reset Link'),
                      ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    print("LOGIN DEBUG: LoginScreen disposing");
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
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

                    // App Logo or Title
                    _buildAppLogo(),

                    SizedBox(height: 8),
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),

                    // Social Sign-In Buttons
                    _buildSocialSignInButtons(),

                    SizedBox(height: 24),

                    // Or divider
                    _buildOrDivider(),

                    SizedBox(height: 24),

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      icon: Icons.email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Password Field
                    _buildTextField(
                      controller: _passwordController,
                      icon: Icons.lock,
                      label: 'Password',
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _showForgotPasswordDialog(context);
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Error Message
                    if (_errorMessage.isNotEmpty) _buildErrorMessage(),

                    // Sign In Button
                    _buildSignInButton(),
                    SizedBox(height: 16),

                    // Sign Up Link
                    _buildSignUpLink(),
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
            onPressed: (_isLoading || _isSocialLoading) ? null : _signInWithGoogle,
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
              onPressed: (_isLoading || _isSocialLoading) ? null : _signInWithApple,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
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
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: Colors.blue,
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
        validator: validator,
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

  Widget _buildSignInButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isLoading || _isSocialLoading) ? null : _signInWithEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
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
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_open, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Sign In',
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

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterScreen(),
              ),
            );
          },
          child: Text(
            'Sign Up',
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