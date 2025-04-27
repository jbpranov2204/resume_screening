import 'package:flutter/material.dart';
import 'package:resume_screening/Mobile_Login_Page.dart';
import 'package:resume_screening/Web_Login_page.dart';

class Responsive extends StatelessWidget {
  const Responsive({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        if (constrains.maxWidth < 600) {
          return MobileLoginPage();
        } else {
          return WebLoginPage();
        }
      },
    );
  }
}
