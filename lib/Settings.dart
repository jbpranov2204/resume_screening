import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/bg7.jpg', fit: BoxFit.cover),
          ),
          // Main content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AppBar with a gradient title
                  AppBar(
                    automaticallyImplyLeading: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Settings',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Account Settings Section
                  _buildSettingsSection('Account Settings', [
                    _buildSettingsItem(Icons.person_outline, 'Edit Profile'),
                    _buildSettingsItem(Icons.lock_outline, 'Change Password'),
                    _buildSettingsItem(Icons.email_outlined, 'Update Email'),
                  ]),
                  SizedBox(height: 32),
                  // App Settings Section
                  _buildSettingsSection('App Settings', [
                    _buildSettingsItem(Icons.notifications_outlined, 'Notifications'),
                    _buildSettingsItem(Icons.language_outlined, 'Language'),
                    _buildSettingsItem(Icons.dark_mode_outlined, 'Dark Mode'),
                  ]),
                  SizedBox(height: 32),
                  // Support Section
                  _buildSettingsSection('Support', [
                    _buildSettingsItem(Icons.help_outline, 'Help & Support'),
                    _buildSettingsItem(Icons.feedback_outlined, 'Send Feedback'),
                    _buildSettingsItem(Icons.info_outline, 'About App'),
                  ]),
                  SizedBox(height: 32),
                  // Sign Out Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Add sign-out functionality
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        shadowColor: Colors.redAccent.withOpacity(0.5),
                        elevation: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title) {
    return InkWell(
      onTap: () {
        // Add navigation or functionality for each setting
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 24),
            SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}