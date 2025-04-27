import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:resume_screening/Mobile_Login_Page.dart';

class MobileSignUpPage extends StatefulWidget {
  const MobileSignUpPage({super.key});

  @override
  State<MobileSignUpPage> createState() => _MobileSignUpPageState();
}

class _MobileSignUpPageState extends State<MobileSignUpPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  late AnimationController _signUpButtonController;
  late AnimationController _shakeController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _pulseAnimationController;

  bool _isFullNameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;
  bool _isLoading = false;
  bool _isSignUpButtonPressed = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<ParticleModel> particles = [];
  final int numberOfParticles = 20;

  @override
  void initState() {
    super.initState();
    _signUpButtonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 30000),
      vsync: this,
    )..repeat();

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fullNameFocusNode.addListener(_handleFullNameFocusChange);
    _emailFocusNode.addListener(_handleEmailFocusChange);
    _passwordFocusNode.addListener(_handlePasswordFocusChange);
    _confirmPasswordFocusNode.addListener(_handleConfirmPasswordFocusChange);
    _initializeParticles();
    HapticFeedback.lightImpact();
  }

  void _initializeParticles() {
    final random = Random();
    for (int i = 0; i < numberOfParticles; i++) {
      particles.add(ParticleModel(random));
    }
  }

  void _handleFullNameFocusChange() {
    setState(() {
      _isFullNameFocused = _fullNameFocusNode.hasFocus;
    });
  }

  void _handleEmailFocusChange() {
    setState(() {
      _isEmailFocused = _emailFocusNode.hasFocus;
    });
  }

  void _handlePasswordFocusChange() {
    setState(() {
      _isPasswordFocused = _passwordFocusNode.hasFocus;
    });
  }

  void _handleConfirmPasswordFocusChange() {
    setState(() {
      _isConfirmPasswordFocused = _confirmPasswordFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _signUpButtonController.dispose();
    _shakeController.dispose();
    _backgroundAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    bool isFocused, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: isFocused ? Theme.of(context).primaryColor : Colors.grey[700],
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(isFocused ? 0.15 : 0.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white30, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2.0,
        ),
      ),
      labelStyle: TextStyle(
        color: isFocused ? Theme.of(context).primaryColor : Colors.white70,
        fontWeight: isFocused ? FontWeight.w500 : FontWeight.normal,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF0F3460),
                      Color(0xFF0D1B2A),
                    ],
                    transform: GradientRotation(
                      _backgroundAnimationController.value * 2 * pi,
                    ),
                  ),
                ),
              );
            },
          ),

          // Animated floating shapes
          Positioned.fill(
            child: CustomPaint(
              painter: NebulaBackgroundPainter(
                time: _backgroundAnimationController.value,
                offset: Offset.zero,
              ),
            ),
          ),

          // Overlay glowing effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, _) {
                return CustomPaint(
                  painter: GlowPainter(
                    progress: _pulseAnimationController.value,
                    offset: Offset.zero,
                  ),
                );
              },
            ),
          ),

          // Main signup card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 300),
                child: _buildSignUpCard(),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: FadeInLeft(
              duration: const Duration(milliseconds: 300),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.all(26),
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeInDown(
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    "SIGN UP",
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Color(0xFF3282B8).withOpacity(0.5),
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInDown(
                  delay: const Duration(milliseconds: 500),
                  child: Text(
                    "Create a new account",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name Field
                FadeInLeft(
                  delay: const Duration(milliseconds: 550),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    transform: Matrix4.translationValues(
                      0,
                      _isFullNameFocused ? -4 : 0,
                      0,
                    ),
                    child: TextFormField(
                      controller: _fullNameController,
                      focusNode: _fullNameFocusNode,
                      decoration: _inputDecoration(
                        "Full Name",
                        Icons.person_outline,
                        _isFullNameFocused,
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            _isFullNameFocused
                                ? FontWeight.w500
                                : FontWeight.normal,
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_emailFocusNode);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Email Field
                FadeInRight(
                  delay: const Duration(milliseconds: 600),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    transform: Matrix4.translationValues(
                      0,
                      _isEmailFocused ? -4 : 0,
                      0,
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      decoration: _inputDecoration(
                        "Email",
                        Icons.email_outlined,
                        _isEmailFocused,
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            _isEmailFocused
                                ? FontWeight.w500
                                : FontWeight.normal,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your email';
                        }
                        final emailRegex = RegExp(
                          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                FadeInLeft(
                  delay: const Duration(milliseconds: 650),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    transform: Matrix4.translationValues(
                      0,
                      _isPasswordFocused ? -4 : 0,
                      0,
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        "Password",
                        Icons.lock_outline_rounded,
                        _isPasswordFocused,
                        suffixIcon: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey[600],
                              key: ValueKey<bool>(_obscurePassword),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            _isPasswordFocused
                                ? FontWeight.w500
                                : FontWeight.normal,
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(
                          context,
                        ).requestFocus(_confirmPasswordFocusNode);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                FadeInRight(
                  delay: const Duration(milliseconds: 700),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    transform: Matrix4.translationValues(
                      0,
                      _isConfirmPasswordFocused ? -4 : 0,
                      0,
                    ),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      obscureText: _obscureConfirmPassword,
                      decoration: _inputDecoration(
                        "Confirm Password",
                        Icons.lock_outline_rounded,
                        _isConfirmPasswordFocused,
                        suffixIcon: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey[600],
                              key: ValueKey<bool>(_obscureConfirmPassword),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            _isConfirmPasswordFocused
                                ? FontWeight.w500
                                : FontWeight.normal,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                // Error message if any
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child:
                      _errorMessage != null
                          ? FadeIn(
                            child: ShakeAnimation(
                              controller: _shakeController,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  top: 18,
                                  bottom: 8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.inter(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          : const SizedBox(height: 20),
                ),

                // Sign Up Button
                FadeInUp(
                  delay: const Duration(milliseconds: 800),
                  child: AnimatedBuilder(
                    animation: _signUpButtonController,
                    builder: (context, child) {
                      final buttonScale = Tween<double>(
                        begin: 1.0,
                        end: 0.95,
                      ).animate(
                        CurvedAnimation(
                          parent: _signUpButtonController,
                          curve: Interval(0.0, 0.5, curve: Curves.easeOut),
                          reverseCurve: Interval(
                            0.5,
                            1.0,
                            curve: Curves.easeIn,
                          ),
                        ),
                      );
                      return GestureDetector(
                        onTap: _handleSignUp,
                        onTapDown: (_) {
                          if (!_isLoading) {
                            setState(() => _isSignUpButtonPressed = true);
                            HapticFeedback.lightImpact();
                          }
                        },
                        onTapUp: (_) {
                          setState(() => _isSignUpButtonPressed = false);
                        },
                        onTapCancel: () {
                          setState(() => _isSignUpButtonPressed = false);
                        },
                        child: Transform.scale(
                          scale:
                              _isSignUpButtonPressed ? 0.98 : buttonScale.value,
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0F4C75), Color(0xFF3282B8)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF3282B8).withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: -5,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                splashColor: Colors.white.withOpacity(0.1),
                                highlightColor: Colors.white.withOpacity(0.05),
                                child: Center(
                                  child:
                                      _isLoading
                                          ? _buildLoadingIndicator()
                                          : Text(
                                            "CREATE ACCOUNT",
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Login link
                FadeInUp(
                  delay: const Duration(milliseconds: 900),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MobileLoginPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Color(0xFF3282B8),
                        ),
                        child: Text(
                          "Login",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF3282B8),
                          ),
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

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Simulate API call
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
          // For demo, show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MobileLoginPage()),
          );
        });
      });
    } else {
      // Show error shake animation
      _shakeController.forward(from: 0.0);
      HapticFeedback.heavyImpact();
    }
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "Creating account...",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ShakeAnimation widget for error states
class ShakeAnimation extends StatelessWidget {
  final Widget child;
  final AnimationController controller;
  final double shakeOffset;

  ShakeAnimation({
    required this.child,
    required this.controller,
    this.shakeOffset = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = controller.value;
        final offsetX = sin(progress * pi * 10) * shakeOffset;

        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: this.child,
        );
      },
    );
  }
}
