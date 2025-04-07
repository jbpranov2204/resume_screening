import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class JobOpeningsPage extends StatefulWidget {
  @override
  _JobOpeningsPageState createState() => _JobOpeningsPageState();
}

class _JobOpeningsPageState extends State<JobOpeningsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Map<String, PlatformFile?> _resumeFiles = {};
  bool _isLoading = false;
  bool _isGridView = true; // Toggle between grid and list view
  String _selectedCategory = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for jobs
  Stream<QuerySnapshot>? _jobsStream;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Initialize jobs stream from Firestore with error handling
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

  // Sample job openings data
  final List<Map<String, dynamic>> _jobOpenings = [];

  // List of job categories for filtering
  final List<String> _categories = [
    'All',
    'Engineering',
    'Design',
    'Marketing',
    'Sales',
    'Product',
  ];

  List<Map<String, dynamic>> get _filteredJobOpenings {
    List<Map<String, dynamic>> filteredList = _jobOpenings;

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      filteredList =
          filteredList.where((job) {
            bool hasMatchingSkill = false;
            for (String skill in job['requiredSkills'] ?? []) {
              if (skill.toLowerCase().contains(searchQuery)) {
                hasMatchingSkill = true;
                break;
              }
            }

            bool hasMatchingTitle = (job['jobTitle'] ?? '')
                .toLowerCase()
                .contains(searchQuery);
            bool hasMatchingCompany = (job['company'] ?? '')
                .toLowerCase()
                .contains(searchQuery);
            return hasMatchingSkill || hasMatchingTitle || hasMatchingCompany;
          }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filteredList =
          filteredList
              .where(
                (job) =>
                    job['category'] == _selectedCategory ||
                    (job['jobTitle'] ?? '').contains(_selectedCategory),
              )
              .toList();
    }

    return filteredList;
  }

  void _pickFile(String jobId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _resumeFiles[jobId] = result.files.first;
        });
      }
    } on PlatformException catch (e) {
      print("Unsupported operation: ${e.toString()}");
    }
  }

  Future<void> _submitResume(String jobId) async {
    if (_resumeFiles[jobId] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload a resume first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final job = _jobOpenings.firstWhere((job) => job['id'] == jobId);
      final resumeFile = _resumeFiles[jobId]!;

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://resume25.pythonanywhere.com/analyze'),
      );

      // Add file to the request
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          resumeFile.bytes!,
          filename: resumeFile.name,
        ),
      );

      // Send the request
      var response = await request.send();

      // Get the response
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      // Print the response to console
      print('Resume Analysis Result:');
      print(jsonResponse);

      // Save analysis results to Firestore
      await _firestore.collection('resume_analysis_results').add({
        'jobId': jobId,
        'jobTitle': job['jobTitle'],
        'analysisResult': jsonResponse,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Resume submitted and analyzed successfully for ${job['jobTitle']} position',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error submitting resume: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit resume: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1100;
    final isTablet =
        MediaQuery.of(context).size.width > 800 &&
        MediaQuery.of(context).size.width <= 1100;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 0, 0, 0), // Dark blue background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(
              Icons.work_outline,
              color: Color(0xFFFFD700),
            ), // Gold icon color
            SizedBox(width: 12),
            Text(
              'JobScope',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(
          255,
          9,
          16,
          22,
        ), // Darker blue for AppBar
        elevation: 0,
        actions: [
          // Removed Notifications, Messages, Profile, and Menu icon
        ],
      ),
      endDrawer: null, // Removed endDrawer
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 5, 13, 23),
                    Color.fromARGB(255, 0, 0, 0),
                  ], // Dark blue to medium blue gradient
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 64.0 : (isTablet ? 32.0 : 16.0),
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section with welcome message
                      _buildHeaderSection(isDesktop),
                      SizedBox(height: 32),

                      // Search and filter section
                      _buildSearchAndFilterSection(isDesktop, isTablet),
                      SizedBox(height: 24),

                      // Toggle view buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Positions',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.grid_view,
                                  color:
                                      _isGridView ? Colors.blue : Colors.grey,
                                ),
                                onPressed:
                                    () => setState(() => _isGridView = true),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.view_list,
                                  color:
                                      !_isGridView ? Colors.blue : Colors.grey,
                                ),
                                onPressed:
                                    () => setState(() => _isGridView = false),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Job listings - use fixed height container with expanded
                      Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _jobsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                              );
                            }

                            // Removed error handling UI
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.work_off,
                                      color: Colors.grey,
                                      size: 64,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No job listings found',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.grey,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Check back later for new opportunities',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Map Firestore documents to job list
                            _jobOpenings.clear();
                            snapshot.data!.docs.forEach((doc) {
                              Map<String, dynamic> job =
                                  doc.data() as Map<String, dynamic>;
                              job['id'] = doc.id; // Add document ID
                              _jobOpenings.add(job);
                            });

                            return _isGridView
                                ? _buildGridView(isDesktop, isTablet)
                                : _buildListView();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFD700),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing your application...',
                        style: GoogleFonts.montserrat(color: Colors.white),
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

  Widget _buildNavItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: InkWell(
        onTap: () {},
        hoverColor: Color(0xFFFFD700).withOpacity(0.1), // Changed hover color
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, color: Color(0xFFE0E0E0), size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(color: Color(0xFFE0E0E0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Color.fromARGB(255, 2, 4, 7), // Changed to dark blue
      child: ListView(
        padding: EdgeInsets.only(
          top: 50.0,
        ), // Added padding to top instead of header
        children: [
          // Removed DrawerHeader widget
          _buildDrawerItem('My Applications', Icons.assignment),
          _buildDrawerItem('Saved Jobs', Icons.bookmark),
          _buildDrawerItem('Notifications', Icons.notifications),
          _buildDrawerItem('Messages', Icons.message),
          _buildDrawerItem('Profile', Icons.account_circle),
          Divider(color: Colors.white24),
          _buildDrawerItem('Settings', Icons.settings),
          _buildDrawerItem('Help & Support', Icons.help),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFFE0E0E0)),
      title: Text(title, style: GoogleFonts.montserrat(color: Colors.white)),
      onTap: () {},
      hoverColor: Color(0xFFFFD700).withOpacity(0.1), // Changed hover color
    );
  }

  Widget _buildHeaderSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Your Next Career Move',
                    style: GoogleFonts.montserrat(
                      fontSize: isDesktop ? 36 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Find opportunities aligned with your skills and experience',
                    style: GoogleFonts.montserrat(
                      fontSize: isDesktop ? 18 : 16,
                      color: const Color.fromARGB(255, 44, 64, 81),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop)
              Container(
                width: 200,
                height: 200,
                child: Icon(
                  Icons.rocket_launch,
                  size: 120,
                  color: Colors.blue[300],
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            _buildStatChip('100+ Companies', Icons.business),
            _buildStatChip('500+ Jobs', Icons.work),
            _buildStatChip('1000+ Applicants', Icons.people),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        label,
        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: Color.fromARGB(
        255,
        34,
        73,
        120,
      ).withOpacity(0.3), // Changed to teal
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildSearchAndFilterSection(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: Color(0xFF0E3B69), // Changed to darker blue
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by job title, company, or skills...',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF1A1A2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              ),
              if (isDesktop || isTablet) SizedBox(width: 16),
              if (isDesktop || isTablet)
                Container(
                  height: 55,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      style: GoogleFonts.montserrat(color: Colors.white),
                      dropdownColor: Color(0xFF1A1A2E),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                      ),
                      items:
                          _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          if (!isDesktop && !isTablet)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    dropdownColor: Color(0xFF1A1A2E),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                    ),
                    items:
                        _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                    hint: Text(
                      'Select Category',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridView(bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isDesktop ? 1.2 : 1.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredJobOpenings.length,
      itemBuilder: (context, index) {
        final job = _filteredJobOpenings[index];
        return _buildGridJobCard(job);
      },
    );
  }

  Widget _buildGridJobCard(Map<String, dynamic> job) {
    final String jobId = job['id'] ?? 'Unknown ID';
    final String title = job['jobTitle'] ?? 'Untitled Job';
    final String company = job['company'] ?? 'No Company';
    final String location = job['location'] ?? 'Unknown Location';
    final List<dynamic> skills = job['requiredSkills'] ?? [];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Color(0xFF0E3B69), // Changed to darker blue
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _showJobDetailsDialog(job),
          borderRadius: BorderRadius.circular(16),
          hoverColor: Color(
            0xFFFFD700,
          ).withOpacity(0.05), // Changed hover color
          splashColor: Color(
            0xFFFFD700,
          ).withOpacity(0.1), // Changed splash color
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company logo placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      company.substring(0, company.length > 0 ? 1 : 0),
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  company,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.blue[200],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child:
                      skills.isNotEmpty
                          ? Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                skills
                                    .take(3)
                                    .map(
                                      (skill) => Chip(
                                        label: Text(
                                          skill.toString(),
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor: Colors.blue.shade700
                                            .withOpacity(0.7),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(),
                          )
                          : Text(
                            'No skills listed',
                            style: GoogleFonts.montserrat(color: Colors.grey),
                          ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showJobDetailsDialog(job),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View Details', style: GoogleFonts.montserrat()),
                      Icon(Icons.arrow_forward, size: 16),
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

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _filteredJobOpenings.length,
      itemBuilder: (context, index) {
        final job = _filteredJobOpenings[index];
        return _buildListJobCard(job, index);
      },
    );
  }

  Widget _buildListJobCard(Map<String, dynamic> job, int index) {
    final String jobId = job['id'] ?? 'Unknown ID';
    final String title = job['jobTitle'] ?? 'Untitled Job';
    final String company = job['company'] ?? 'No Company';
    final String location = job['location'] ?? 'Unknown Location';
    final String salary = job['salary'] ?? 'Not Disclosed';
    final List<dynamic> skills = job['requiredSkills'] ?? [];

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF0D518C), // Changed to medium blue
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showJobDetailsDialog(job),
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.blue.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    company.substring(0, company.length > 0 ? 1 : 0),
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            salary,
                            style: GoogleFonts.montserrat(
                              color: Colors.blue[200],
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      company,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.blue[200],
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          location,
                          style: GoogleFonts.montserrat(color: Colors.white70),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          skills
                              .take(4)
                              .map(
                                (skill) => Chip(
                                  label: Text(
                                    skill.toString(),
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: Colors.blue.shade700
                                      .withOpacity(0.7),
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _pickFile(jobId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.blue.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text('Upload Resume'),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _showJobDetailsDialog(job),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text('View Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobDetailsDialog(Map<String, dynamic> job) {
    final String jobId = job['id'] ?? 'Unknown ID';
    final String title = job['jobTitle'] ?? 'Untitled Job';
    final String company = job['company'] ?? 'No Company';
    final String location = job['location'] ?? 'Unknown Location';
    final String salary = job['salary'] ?? 'Not Disclosed';
    final String experienceLevel = job['experienceLevel'] ?? 'Not Specified';
    final String employmentType = job['employmentType'] ?? 'Not Specified';
    final String description =
        job['jobDescription'] ?? 'No Description Available';
    final List<dynamic> skills = job['requiredSkills'] ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Color(0xFF16213E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              children: [
                // Job header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(0xFF0F3460),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        company,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          color: Colors.blue[200],
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            location,
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Job details
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job highlights
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildHighlightItem(Icons.attach_money, salary),
                              VerticalDivider(color: Colors.white30, width: 40),
                              _buildHighlightItem(Icons.work, employmentType),
                              VerticalDivider(color: Colors.white30, width: 40),
                              _buildHighlightItem(
                                Icons.timeline,
                                experienceLevel,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Job description
                        Text(
                          'Job Description',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          description,
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            height: 1.5,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Required skills
                        Text(
                          'Required Skills',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              skills.map((skill) {
                                return Chip(
                                  label: Text(
                                    skill.toString(),
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: Colors.blue.shade800,
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 24),

                        // Upload resume
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade700.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apply for this position',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _pickFile(jobId),
                                    icon: Icon(Icons.upload_file),
                                    label: Text('Choose Resume'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.grey[700],
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _resumeFiles[jobId]?.name ??
                                          'No file selected',
                                      style: TextStyle(color: Colors.white70),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _submitResume(jobId),
                                  icon: Icon(Icons.send),
                                  label: Text(
                                    'Submit Application',
                                    style: GoogleFonts.montserrat(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHighlightItem(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[200], size: 24),
          SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.montserrat(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label + ':',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}