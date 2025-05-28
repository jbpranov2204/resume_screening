import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import 'package:resume_screening/dashboard.dart';
import 'package:animate_do/animate_do.dart';
import 'package:resume_screening/Signup_page.dart';
import 'package:resume_screening/user_page.dart';

class MobileLoginPage extends StatefulWidget {
  const MobileLoginPage({super.key});

  @override
  State<MobileLoginPage> createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends State<MobileLoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late AnimationController _loginButtonController;
  late AnimationController _shakeController;

  // New animated controllers for enhanced effects
  late AnimationController _backgroundAnimationController;
  late AnimationController _pulseAnimationController;

  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isLoading = false;
  bool _isLoginButtonPressed = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  final List<ParticleModel> particles = [];
  final int numberOfParticles = 20;

  @override
  void initState() {
    super.initState();
    _loginButtonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Initialize new animation controllers
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 30000),
      vsync: this,
    )..repeat();

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _emailFocusNode.addListener(_handleEmailFocusChange);
    _passwordFocusNode.addListener(_handlePasswordFocusChange);
    _initializeParticles();
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _loginButtonController.dispose();
    _shakeController.dispose();
    _backgroundAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    bool isFocused,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: isFocused ? Theme.of(context).primaryColor : Colors.grey[700],
      ),
      suffixIcon:
          label == "Password"
              ? IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
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
                  HapticFeedback.selectionClick();
                },
              )
              : null,
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
          // New animated background with gradient but without motion effects
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

          // Animated floating shapes - remove offset parameter
          Positioned.fill(
            child: CustomPaint(
              painter: NebulaBackgroundPainter(
                time: _backgroundAnimationController.value,
                offset: Offset.zero, // Fixed offset to prevent motion
              ),
            ),
          ),

          // Overlay glowing effect - remove offset parameter
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnimationController,
              builder: (context, _) {
                return CustomPaint(
                  painter: GlowPainter(
                    progress: _pulseAnimationController.value,
                    offset: Offset.zero, // Fixed offset to prevent motion
                  ),
                );
              },
            ),
          ),

          // Animated "Job Openings" marquee with improved design
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => JobOpeningsPage()),
                  );
                },
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF3282B8).withOpacity(0.8),
                        Color(0xFF0F4C75).withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3282B8).withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: -2,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.work_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.45,
                        height: 22,
                        child: Marquee(
                          text:
                              'Job Openings • Find Your Dream Job • Apply Now • ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          scrollAxis: Axis.horizontal,
                          blankSpace: 30.0,
                          velocity: 40.0,
                          pauseAfterRound: Duration(seconds: 1),
                          startPadding: 10.0,
                          accelerationDuration: Duration(seconds: 1),
                          accelerationCurve: Curves.linear,
                          decelerationDuration: Duration(milliseconds: 500),
                          decelerationCurve: Curves.easeOut,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main login card without motion effects
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 300),
                child: _buildLoginCard(),
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
      transform: Matrix4.translationValues(0, _isLoading ? -10.0 : 0.0, 0),
      child: ClipRRect(
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
                      "WELCOME",
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
                      "Sign in to continue",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInLeft(
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
                          FocusScope.of(
                            context,
                          ).requestFocus(_passwordFocusNode);
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
                  FadeInRight(
                    delay: const Duration(milliseconds: 700),
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
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              _isPasswordFocused
                                  ? FontWeight.w500
                                  : FontWeight.normal,
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
                  FadeInRight(
                    delay: const Duration(milliseconds: 800),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child:
                        _errorMessage != null
                            ? FadeIn(
                              child: ShakeAnimation(
                                controller: _shakeController,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    top: 12,
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
                            : const SizedBox(height: 12),
                  ),
                  FadeInUp(
                    delay: const Duration(milliseconds: 900),
                    child: AnimatedBuilder(
                      animation: _loginButtonController,
                      builder: (context, child) {
                        final buttonScale = Tween<double>(
                          begin: 1.0,
                          end: 0.95,
                        ).animate(
                          CurvedAnimation(
                            parent: _loginButtonController,
                            curve: Interval(0.0, 0.5, curve: Curves.easeOut),
                            reverseCurve: Interval(
                              0.5,
                              1.0,
                              curve: Curves.easeIn,
                            ),
                          ),
                        );
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DashboardPage(),
                              ),
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
                            scale:
                                _isLoginButtonPressed
                                    ? 0.98
                                    : buttonScale.value,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF0F4C75),
                                    Color(0xFF3282B8),
                                  ],
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
                                  highlightColor: Colors.white.withOpacity(
                                    0.05,
                                  ),
                                  child: Center(
                                    child:
                                        _isLoading
                                            ? _buildLoadingIndicator()
                                            : Text(
                                              "SIGN IN",
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
                  FadeInUp(
                    delay: const Duration(milliseconds: 1000),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
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
                                builder: (context) => SignUpPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF3282B8),
                          ),
                          child: Text(
                            "Register",
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
          "Signing in...",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String iconAsset, Color color) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: -5,
            ),
          ],
        ),
      ),
    );
  }
}

// Advanced particle painter for nebula effect
class NebulaBackgroundPainter extends CustomPainter {
  final double time;
  final Offset
  offset; // Keep the parameter, but it will be fixed as Offset.zero

  NebulaBackgroundPainter({required this.time, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);
    final stars = 100;

    // Draw stars without parallax effect
    for (int i = 0; i < stars; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final radius = rnd.nextDouble() * 1.5 + 0.5;

      // Make stars twinkle
      final twinkle = (sin((time * 10) + (i * 0.1)) + 1) / 2;

      final paint =
          Paint()
            ..color = Colors.white.withOpacity(0.4 + (twinkle * 0.6))
            ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y), // Remove dx, dy to prevent motion
        radius * (0.8 + (twinkle * 0.4)),
        paint,
      );
    }

    // Draw nebula clouds without motion
    for (int i = 0; i < 4; i++) {
      final cloudRadius = size.width * (0.4 + rnd.nextDouble() * 0.3);
      final cloudX = size.width * (0.3 + rnd.nextDouble() * 0.4);
      final cloudY = size.height * (0.3 + rnd.nextDouble() * 0.4);

      final gradient = RadialGradient(
        colors: [
          Color(0xFF3282B8).withOpacity(0.05 + (i * 0.02)),
          Color(0xFF0F4C75).withOpacity(0.01),
          Colors.transparent,
        ],
        stops: [0.0, 0.6, 1.0],
      );

      final rect = Rect.fromCircle(
        center: Offset(cloudX, cloudY),
        radius: cloudRadius,
      );

      final paint =
          Paint()
            ..shader = gradient.createShader(rect)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(cloudX, cloudY), cloudRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Glow effect painter
class GlowPainter extends CustomPainter {
  final double progress;
  final Offset offset;

  GlowPainter({required this.progress, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width * 0.5, // Remove offset influence
      size.height * 0.4, // Remove offset influence
    );

    final radius = size.height * (0.4 + progress * 0.1);

    final gradient = RadialGradient(
      colors: [
        Color(0xFF3282B8).withOpacity(0.2 * (1 - progress)),
        Color(0xFF0F4C75).withOpacity(0.1 * (1 - progress)),
        Colors.transparent,
      ],
      stops: [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint =
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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

    x = Tween<double>(
      begin: 0,
      end: 1,
    ).chain(CurveTween(curve: Curves.easeInOut));
    y = Tween<double>(
      begin: random.nextDouble(),
      end: random.nextDouble(),
    ).chain(CurveTween(curve: Curves.easeInOut));
    size = Tween<double>(
      begin: 2 + random.nextDouble() * 4,
      end: 6 + random.nextDouble() * 8,
    ).chain(CurveTween(curve: Curves.easeInOut));
    speed = Tween<double>(
      begin: 0.05,
      end: 0.1 + random.nextDouble() * 0.1,
    ).chain(CurveTween(curve: Curves.easeInOut));
    opacity = Tween<double>(
      begin: 0.1 + random.nextDouble() * 0.3,
      end: 0.3 + random.nextDouble() * 0.2,
    ).chain(CurveTween(curve: Curves.easeInOut));
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

      final paint =
          Paint()
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
