import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resume_screening/2_page.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  final String _username = "John Doe";
  late AnimationController _animationController;
  
  // Sample job history data
  final List<Map<String, dynamic>> _jobHistory = [
    {
      'title': 'Flutter Developer',
      'company': 'Tech Solutions Inc.',
      'date': '2023-05-15',
      'applicants': 24,
      'status': 'Active',
    },
    {
      'title': 'Machine Learning Engineer',
      'company': 'AI Innovations',
      'date': '2023-04-10',
      'applicants': 18,
      'status': 'Closed',
    },
    {
      'title': 'Full Stack Developer',
      'company': 'WebWorks Ltd.',
      'date': '2023-03-22',
      'applicants': 32,
      'status': 'Active',
    },
    {
      'title': 'Mobile App Developer',
      'company': 'AppGenius',
      'date': '2023-02-05',
      'applicants': 15,
      'status': 'Closed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showProfileMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade800),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage('https://randomuser.me/api/portraits/men/1.jpg'),
                ),
                SizedBox(height: 16),
                Text(
                  _username,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'john.doe@example.com',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 24),
                _buildProfileMenuItem(Icons.person, 'Edit Profile'),
                _buildProfileMenuItem(Icons.settings, 'Settings'),
                _buildProfileMenuItem(Icons.help_outline, 'Help & Support'),
                Divider(color: Colors.grey.shade800),
                _buildProfileMenuItem(Icons.logout, 'Sign Out', isSignOut: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String title, {bool isSignOut = false}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Add specific actions for each menu item
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSignOut ? Colors.redAccent : Colors.white,
              size: 20,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isSignOut ? Colors.redAccent : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToJobUpload() {
    // Navigate to job upload page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDescriptionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _showProfileMenu,
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://randomuser.me/api/portraits/men/1.jpg'),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: 'Welcome back, '),
                  TextSpan(
                    text: _username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage your job listings and review applicants',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 32),
            
            // Stats overview
            Row(
              children: [
                _buildStatCard('Active Jobs', '2', Icons.work_outline),
                SizedBox(width: 16),
                _buildStatCard('Total Applicants', '74', Icons.people_outline),
                SizedBox(width: 16),
                _buildStatCard('Pending Review', '12', Icons.pending_outlined),
              ],
            ),
            
            SizedBox(height: 32),
            
            // Job History section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Job Listings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all jobs
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Job history list
            ..._jobHistory.map((job) => _buildJobHistoryCard(job)),
            
            SizedBox(height: 40),
            
            // Add new job button
            Center(
              child: ElevatedButton(
                onPressed: _navigateToJobUpload,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: Colors.blue.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline),
                    SizedBox(width: 12),
                    Text(
                      'Post New Job',
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
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobHistoryCard(Map<String, dynamic> job) {
    final bool isActive = job['status'] == 'Active';
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to job details
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        job['status'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  job['company'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${job['applicants']} applicants',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Posted: ${job['date']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

