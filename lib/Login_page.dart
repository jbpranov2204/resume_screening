import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resume_screening/1_page.dart';
import 'package:resume_screening/new.dart';
import 'package:resume_screening/2_page.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';
import 'package:animate_do/animate_do.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes to track field focus states
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Animation controllers
  late AnimationController _loginButtonController;
  late AnimationController _shakeController;

  // Track field focus states for animations
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isLoading = false;
  bool _isLoginButtonPressed = false;
  String? _errorMessage;

  // Controls whether to show the password
  bool _obscurePassword = true;

  // Animated background properties
  final List<ParticleModel> particles = [];
  final int numberOfParticles = 30;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _loginButtonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Setup focus listeners for field animations
    _emailFocusNode.addListener(_handleEmailFocusChange);
    _passwordFocusNode.addListener(_handlePasswordFocusChange);

    // Initialize animated background particles
    _initializeParticles();

    // Add haptic feedback for better tactile experience
    HapticFeedback.lightImpact();
  }

  void _initializeParticles() {
    final random = Random();
    for (int i = 0; i < numberOfParticles; i++) {
      particles.add(ParticleModel(random));
    }
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

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _loginButtonController.dispose();
    _shakeController.dispose();
    super.dispose();
  }



  void _playErrorAnimation() {
    // Play shake animation
    _shakeController.forward(from: 0.0);
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });
  }

  // Enhanced input decoration with animations
  InputDecoration _inputDecoration(String label, IconData icon, bool isFocused) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: isFocused ? Theme.of(context).primaryColor : Colors.grey[700],
      ),
      suffixIcon: label == "Password"
          ? IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                  key: ValueKey<bool>(_obscurePassword),
                ),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
                // Add micro-interaction feedback
                HapticFeedback.selectionClick();
              },
            )
          : null,
      filled: true,
      fillColor: Colors.white.withOpacity(isFocused ? 0.95 : 0.85),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2.0,
        ),
      ),
      labelStyle: TextStyle(
        color: isFocused ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isFocused ? FontWeight.w500 : FontWeight.normal,
      ),
      // Add subtle shadow when focused
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Side: Background with asset image and professional text
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                // Use the asset image as the background
              Stack(
  children: [
    SizedBox.expand(
      child: Image.asset(
        'assets/n.jpg',
        fit: BoxFit.cover,
      ),
    ),
    Container(
      // Your content goes here
    ),
  ],
),

                // Optional: retain a subtle particle animation
                CustomPaint(
                  painter: ParticlesPainter(particles),
                  child: Container(),
                ),
                // Professional text in the center of the left side
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "Empowering Your Business with Innovative Technology",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right Side: Login Content
          Expanded(
            flex: 3,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 300),
                      child: _buildLoginCard(),
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

  Widget _buildLoginCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      transform: Matrix4.translationValues(
        0,
        _isLoading ? -10.0 : 0.0,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _isLoading ? 10 : 20,
            sigmaY: _isLoading ? 10 : 20,
          ),
          child: AnimatedContainer( // Using AnimatedContainer for animated properties
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(32),
            width: 400,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(_isLoading ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 5),
                )
              ]
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with staggered animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      "Welcome Back!",
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle with staggered animation
                  FadeInDown(
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      "Login to continue",
                      style: GoogleFonts.poppins(
                        color: Colors.black54,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Email Field with animation
                  FadeInLeft(
                    delay: const Duration(milliseconds: 600),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                        0,
                        _isEmailFocused ? -5 : 0,
                        0,
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        decoration: _inputDecoration("Email", Icons.email, _isEmailFocused),
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: _isEmailFocused ? FontWeight.w500 : FontWeight.normal,
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
                          final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password Field with animation
                  FadeInRight(
                    delay: const Duration(milliseconds: 700),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                        0,
                        _isPasswordFocused ? -5 : 0,
                        0,
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration("Password", Icons.lock, _isPasswordFocused),
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: _isPasswordFocused ? FontWeight.w500 : FontWeight.normal,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Forgot Password link with animation
                  FadeInRight(
                    delay: const Duration(milliseconds: 800),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black54,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1.5,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Error message with animation
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _errorMessage != null
                        ? FadeIn(
                            child: ShakeAnimation(
                              controller: _shakeController,
                              child: Container(
                                margin: const EdgeInsets.only(top: 16, bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.poppins(
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
                        : const SizedBox(height: 16),
                  ),

                  // Login Button with animations
                  FadeInUp(
                    delay: const Duration(milliseconds: 900),
                    child: AnimatedBuilder(
                      animation: _loginButtonController,
                      builder: (context, child) {
                        final buttonScale = Tween<double>(begin: 1.0, end: 0.95)
                            .animate(CurvedAnimation(
                          parent: _loginButtonController,
                          curve: Interval(0.0, 0.5, curve: Curves.easeOut),
                          reverseCurve: Interval(0.5, 1.0, curve: Curves.easeIn),
                        ));

                        return GestureDetector(
                          onTap:(){
                            Navigator.push(
                            context,
                             MaterialPageRoute(builder: (context) => DashboardPage()),
                             );
                          },
                          onTapDown: (_) {
                            if (!_isLoading) {
                              setState(() => _isLoginButtonPressed = true);
                              HapticFeedback.lightImpact();
                            }
                          },
                          onTapUp: (_) {
                            setState(() => _isLoginButtonPressed = false);
                          },
                          onTapCancel: () {
                            setState(() => _isLoginButtonPressed = false);
                          },
                          child: Transform.scale(
                            scale: _isLoginButtonPressed ? 0.98 : buttonScale.value,
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade600,
                                    Colors.blue.shade800,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 5),
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
                                    child: _isLoading
                                        ? _buildLoadingIndicator()
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Login",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ],
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

                  // Signup section with animations
                  FadeInUp(
                    delay: const Duration(milliseconds: 1000),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                          child: Text(
                            "Sign up",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Social login options with animations
                  FadeInUp(
                    delay: const Duration(milliseconds: 1100),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        children: [
                          Text(
                            "Or continue with",
                            style: GoogleFonts.poppins(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialButton(Icons.g_mobiledata, Colors.red),
                              const SizedBox(width: 16),
                              _buildSocialButton(Icons.facebook, Colors.blue),
                              const SizedBox(width: 16),
                              _buildSocialButton(Icons.apple, Colors.black),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          "Logging in...",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}

// Particle model for animated background
class ParticleModel {
  late Animatable<double> x;
  late Animatable<double> y;
  late Animatable<double> size;
  late Animatable<double> speed;
  late Animatable<double> opacity;
  late Color color;

  ParticleModel(Random random) {
    final colors = [Colors.white, Colors.blueAccent, Colors.lightBlueAccent];

    x = Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeInOut));
    y = Tween<double>(begin: random.nextDouble(), end: random.nextDouble())
        .chain(CurveTween(curve: Curves.easeInOut));
    size = Tween<double>(begin: 2 + random.nextDouble() * 4, end: 6 + random.nextDouble() * 8)
        .chain(CurveTween(curve: Curves.easeInOut));
    speed = Tween<double>(begin: 0.05, end: 0.1 + random.nextDouble() * 0.1)
        .chain(CurveTween(curve: Curves.easeInOut));
    opacity = Tween<double>(begin: 0.1 + random.nextDouble() * 0.3, end: 0.3 + random.nextDouble() * 0.2)
        .chain(CurveTween(curve: Curves.easeInOut));
    color = colors[random.nextInt(colors.length)];
  }
}

// Custom painter for animated background
class ParticlesPainter extends CustomPainter {
  final List<ParticleModel> particles;

  ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 4000;

    for (final particle in particles) {
      final progress = (time * particle.speed.transform(time)) % 1.0;
      final xPos = particle.x.transform(progress) * size.width;
      final yPos = particle.y.transform(progress) * size.height;
      final particleSize = particle.size.transform(progress);
      final opacity = particle.opacity.transform(progress);

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(xPos, yPos), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Shake animation for error states
class ShakeAnimation extends StatelessWidget {
  final Widget child;
  final AnimationController controller;
  final double shakeOffset;

  ShakeAnimation({
    required this.child,
    required this.controller,
    this.shakeOffset = 10.0,
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
