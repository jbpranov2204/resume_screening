import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resume_screening/2_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:resume_screening/Settings.dart';
import 'package:resume_screening/analytics_page.dart';
import 'package:resume_screening/candidates.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final String _username = "Yuva Krishna";
  late AnimationController _animationController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot>? _jobsStream;
  int _selectedIndex = 0;
  bool _isDrawerOpen = true;

  // Get screen width to determine layout
  double _getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  bool get _isLargeScreen => _getScreenWidth(context) > 1200;
  bool get _isMediumScreen =>
      _getScreenWidth(context) > 800 && _getScreenWidth(context) <= 1200;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    try {
      _jobsStream = _firestore.collection('jobs').snapshots();
    } catch (e) {
      print('Error initializing Firestore stream: $e');
    }
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
                  backgroundImage: NetworkImage(
                    'https://upload.wikimedia.org/wikipedia/commons/6/66/Sachin-Tendulkar.jpg',
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  _username,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'yuvabroo@gmail.com',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 24),
                _buildProfileMenuItem(Icons.person, 'Edit Profile'),
                _buildProfileMenuItem(Icons.settings, 'Settings'),
                _buildProfileMenuItem(Icons.help_outline, 'Help & Support'),
                Divider(color: Colors.grey.shade800),
                _buildProfileMenuItem(
                  Icons.logout,
                  'Sign Out',
                  isSignOut: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileMenuItem(
    IconData icon,
    String title, {
    bool isSignOut = false,
  }) {
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDescriptionPage()),
    );
  }

  void _navigateToCandidates() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CandidatesPage()),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AnalyticsPage()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = _getScreenWidth(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/bg7.jpg', fit: BoxFit.cover),
          ),

          // Main content as Row for web layout
          Positioned.fill(
            child: Row(
              children: [
                // Sidebar/Navigation
                if (_isLargeScreen || (_isMediumScreen && _isDrawerOpen))
                  _buildWebSidebar(),

                // Main content area
                Expanded(
                  child: Container(
                    color: Colors.black.withOpacity(
                      0.6,
                    ), // Semi-transparent overlay
                    child: Column(
                      children: [
                        // Top AppBar
                        _buildWebAppBar(screenWidth),

                        // Content Area with scrolling
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome message
                                _buildWelcomeHeader(),

                                SizedBox(height: 32),

                                // Stats overview with responsive grid
                                _buildStatsGrid(screenWidth),

                                SizedBox(height: 32),

                                // Job Listings section
                                _buildJobListingsHeader(),

                                SizedBox(height: 16),

                                // Job listing cards
                                _buildJobListings(),

                                SizedBox(height: 40),
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
          ),
        ],
      ),
      // Only show FAB on smaller screens
      floatingActionButton:
          !_isLargeScreen && !_isMediumScreen
              ? FloatingActionButton(
                backgroundColor: Colors.blue,
                child: Icon(Icons.add),
                onPressed: _navigateToJobUpload,
              )
              : null,
      drawer: !_isLargeScreen && !_isMediumScreen ? _buildMobileDrawer() : null,
    );
  }

  Widget _buildWebSidebar() {
    return Container(
      width: 250,
      color: Colors.black.withOpacity(0.8),
      child: Column(
        children: [
          SizedBox(height: 40),

          // Logo/Brand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.file_copy, color: Colors.blue, size: 28),
                SizedBox(width: 10),
                Text(
                  'ResumeScreen',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 50),

          // Navigation items
          _buildNavItem(0, Icons.dashboard, 'Dashboard'),
          _buildNavItem(
            1,
            Icons.work_outline,
            'Jobs',
            onTap: _navigateToJobUpload,
          ),
          _buildNavItem(
            2,
            Icons.people_outline,
            'Candidates',
            onTap: _navigateToCandidates,
          ),
          _buildNavItem(
            3,
            Icons.analytics_outlined,
            'Analytics',
            onTap: _navigateToAnalytics,
          ),
          _buildNavItem(4, Icons.settings_outlined, 'Settings'),

          Expanded(child: SizedBox()),

          // User profile at bottom
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(
                    'https://upload.wikimedia.org/wikipedia/commons/6/66/Sachin-Tendulkar.jpg',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Admin',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.white, size: 18),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final isSelected = index == _selectedIndex;

    return InkWell(
      onTap:
          onTap ??
          () {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 4) {
              // Settings index
              _navigateToSettings();
            }
          },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey.shade400,
              size: 20,
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Container(
        color: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey.shade900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      'https://upload.wikimedia.org/wikipedia/commons/6/66/Sachin-Tendulkar.jpg',
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _username,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Admin',
                    style: GoogleFonts.poppins(
                      color: Colors.blue.shade200,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildNavItem(0, Icons.dashboard, 'Dashboard'),
            _buildNavItem(
              1,
              Icons.work_outline,
              'Jobs',
              onTap: _navigateToJobUpload,
            ),
            _buildNavItem(
              2,
              Icons.people_outline,
              'Candidates',
              onTap: _navigateToCandidates,
            ),
            _buildNavItem(3, Icons.analytics_outlined, 'Analytics'),
            _buildNavItem(4, Icons.settings_outlined, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildWebAppBar(double screenWidth) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
      ),
      child: Row(
        children: [
          // For smaller screen sizes, show menu toggle
          if (!_isLargeScreen)
            IconButton(
              icon: Icon(
                _isDrawerOpen ? Icons.menu_open : Icons.menu,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isDrawerOpen = !_isDrawerOpen;
                });
              },
            ),

          // Page title
          if (!_isLargeScreen && !_isMediumScreen)
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

          // Search box (only on large screens)
          if (_isLargeScreen || _isMediumScreen)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 40,
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Icon buttons for actions
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            color: Colors.white,
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.message_outlined),
            color: Colors.white,
            onPressed: () {},
          ),

          // Profile avatar
          if (_isLargeScreen || _isMediumScreen)
            GestureDetector(
              onTap: _showProfileMenu,
              child: Row(
                children: [
                  SizedBox(width: 12),
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      'https://upload.wikimedia.org/wikipedia/commons/6/66/Sachin-Tendulkar.jpg',
                    ),
                  ),
                  if (_isLargeScreen)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _username,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $_username',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage your job listings and review applicants from your dashboard',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: _navigateToJobUpload,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text(
                      'Post New Job',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              OutlinedButton(
                onPressed: _navigateToCandidates,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: BorderSide(color: Colors.grey.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people),
                    SizedBox(width: 8),
                    Text(
                      'View Candidates',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(double screenWidth) {
    // Determine number of cards per row based on screen width
    int crossAxisCount = _isLargeScreen ? 4 : (_isMediumScreen ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Active Jobs', '2', Icons.work_outline, Colors.blue),
        _buildStatCard(
          'Total Applicants',
          '74',
          Icons.people_outline,
          Colors.orange,
        ),
        _buildStatCard(
          'Pending Review',
          '12',
          Icons.pending_outlined,
          Colors.purple,
        ),
        _buildStatCard('Interviews', '8', Icons.calendar_today, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return HoverContainer(
      hoverBorderColor: color,
      defaultBorderColor: Colors.grey.shade800,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      hoverTransform: Matrix4.translationValues(0, -5, 0),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobListingsHeader() {
    return Row(
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
        TextButton.icon(
          icon: Icon(Icons.visibility),
          label: Text('View All'),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
          onPressed: () {
            // Navigate to all jobs
          },
        ),
      ],
    );
  }

  Widget _buildJobListings() {
    return StreamBuilder<QuerySnapshot>(
      stream: _jobsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Error loading jobs');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard('No job listings found');
        }

        // For web, use a grid layout for job cards on larger screens
        if (_isLargeScreen || _isMediumScreen) {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _isLargeScreen ? 3 : 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: snapshot.data!.docs.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              Map<String, dynamic> job =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              job['id'] = snapshot.data!.docs[index].id;
              return _buildJobCard(job);
            },
          );
        } else {
          // Use list for smaller screens
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              Map<String, dynamic> job =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              job['id'] = snapshot.data!.docs[index].id;
              return _buildJobCard(job);
            },
          );
        }
      },
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade800),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(message, style: GoogleFonts.poppins(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_off_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(color: Colors.grey.shade400),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Create Job Listing'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _navigateToJobUpload,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final String title = job['jobTitle'] ?? 'Untitled Job';
    final String status = job['employmentType'] ?? 'Unknown';
    final String company = job['company'] ?? 'No Company';
    final int applicants = job['applicants'] ?? 0;
    final Timestamp? timestamp = job['postedAt'];
    final String date =
        timestamp != null
            ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
            : 'No date available';
    final bool isActive = status == 'Active';

    return HoverContainer(
      hoverBorderColor: Colors.blue,
      defaultBorderColor: Colors.grey.shade800,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
      hoverTransform: Matrix4.translationValues(0, -3, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to job details
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.work_outline, color: Colors.blue),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            company,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isActive ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$applicants applicants',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Posted: $date',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Action for viewing details
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

class HoverContainer extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Color hoverBorderColor;
  final Color defaultBorderColor;
  final List<BoxShadow>? boxShadow;
  final List<BoxShadow>? hoverBoxShadow;
  final Matrix4? hoverTransform;

  const HoverContainer({
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.hoverBorderColor = Colors.blue,
    this.defaultBorderColor = Colors.grey,
    this.boxShadow,
    this.hoverBoxShadow,
    this.hoverTransform,
  });

  @override
  _HoverContainerState createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Create safe hover shadows
    List<BoxShadow> hoverShadows = [];

    // Only process shadows if boxShadow is provided
    if (widget.hoverBoxShadow != null) {
      hoverShadows = widget.hoverBoxShadow!;
    } else if (widget.boxShadow != null && widget.boxShadow!.isNotEmpty) {
      try {
        hoverShadows =
            widget.boxShadow!
                .map(
                  (shadow) => BoxShadow(
                    color: shadow.color.withOpacity(
                      (shadow.color.opacity + 0.3).clamp(0.0, 1.0),
                    ),
                    blurRadius: shadow.blurRadius * 1.5,
                    spreadRadius: shadow.spreadRadius * 1.5,
                    offset: shadow.offset,
                  ),
                )
                .toList();
      } catch (e) {
        // Fallback to an empty list if there's an error
        print('Error processing shadow: $e');
        hoverShadows = [];
      }
    }

    // Safely create transform matrix
    Matrix4 transform = Matrix4.identity();
    try {
      if (_isHovered) {
        // Use provided transform or default scale up
        transform =
            widget.hoverTransform ?? Matrix4.identity()
              ..scale(1.03);
      }
    } catch (e) {
      print('Error applying transform: $e');
      // Fallback to identity matrix on error
      transform = Matrix4.identity();
    }

    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() => _isHovered = false);
        }
      },
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: transform,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: Border.all(
            color:
                _isHovered
                    ? widget.hoverBorderColor
                    : widget.defaultBorderColor,
            width: _isHovered ? 2.0 : 1.0,
          ),
          boxShadow: _isHovered ? hoverShadows : widget.boxShadow,
        ),
        child: widget.child,
      ),
    );
  }
}
