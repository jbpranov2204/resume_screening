import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Check if we're on mobile based on screen width
    final bool isMobile = MediaQuery.of(context).size.width < 600;

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
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AppBar with a gradient title
                  AppBar(
                    automaticallyImplyLeading: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: ShaderMask(
                      shaderCallback:
                          (bounds) => LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                      child: Text(
                        'Settings',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 20 : 24,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  // Account Settings Section
                  _buildSettingsSection('Account Settings', [
                    _buildSettingsItem(Icons.person_outline, 'Edit Profile'),
                    _buildSettingsItem(Icons.lock_outline, 'Change Password'),
                    _buildSettingsItem(Icons.email_outlined, 'Update Email'),
                  ], isMobile),
                  SizedBox(height: isMobile ? 24 : 32),
                  // App Settings Section
                  _buildSettingsSection('App Settings', [
                    _buildSettingsItem(
                      Icons.notifications_outlined,
                      'Notifications',
                    ),
                    _buildSettingsItem(Icons.language_outlined, 'Language'),
                    _buildSettingsItem(Icons.dark_mode_outlined, 'Dark Mode'),
                  ], isMobile),
                  SizedBox(height: isMobile ? 24 : 32),
                  // Support Section
                  _buildSettingsSection('Support', [
                    _buildSettingsItem(Icons.help_outline, 'Help & Support'),
                    _buildSettingsItem(
                      Icons.feedback_outlined,
                      'Send Feedback',
                    ),
                    _buildSettingsItem(Icons.info_outline, 'About App'),
                  ], isMobile),
                  SizedBox(height: isMobile ? 24 : 32),
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
                          horizontal: isMobile ? 24 : 32,
                          vertical: isMobile ? 12 : 16,
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
                          Icon(Icons.logout, size: isMobile ? 18 : 20),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14 : 16,
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

  Widget _buildSettingsSection(
    String title,
    List<Widget> items,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        ...items,
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title) {
    return Builder(
      builder: (context) {
        final bool isMobile = MediaQuery.of(context).size.width < 600;

        return InkWell(
          onTap: () {
            // Add navigation or functionality for each setting
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 12 : 16,
              horizontal: isMobile ? 10 : 12,
            ),
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
                Icon(icon, color: Colors.blueAccent, size: isMobile ? 20 : 24),
                SizedBox(width: isMobile ? 12 : 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: isMobile ? 14 : 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
