import 'package:flutter/material.dart';
import 'package:resume_screening/Login_page.dart';
import 'package:resume_screening/Signup_page.dart';

// import '../pages/signup_page.dart'; // (Optional for future expansion)

class AppRoutes {
  static const String login = '/';
  static const String signup = '/signup';

  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    signup: (context) => const SignUpPage(),
    // signup: (context) => const SignupPage(), // (Optional)
  };
}
