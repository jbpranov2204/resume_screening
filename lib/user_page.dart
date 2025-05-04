import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

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

  // Add this method for resume analysis
  Future<Map<String, dynamic>> _analyzeResume(PlatformFile resumeFile) async {
    int retryCount = 0;
    const maxRetries = 2; // Maximum number of retry attempts

    while (retryCount <= maxRetries) {
      try {
        // Log file information for debugging
        print(
          'Analyzing resume: ${resumeFile.name}, Size: ${resumeFile.size} bytes',
        );

        // Create a multipart request to the resume analysis API
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
            'https://resume-2kvb.onrender.com/',
          ), // Updated endpoint with explicit 'analyze' path
        );

        if (kIsWeb) {
          // Web platform handling
          final bytes = resumeFile.bytes;
          final filename = resumeFile.name;
          if (bytes != null) {
            print('Uploading web file: $filename, ${bytes.length} bytes');
            request.files.add(
              http.MultipartFile.fromBytes('file', bytes, filename: filename),
            );
          } else {
            throw Exception(
              "Resume file bytes are null. Please upload a valid resume.",
            );
          }
        } else {
          // Mobile/Desktop platform handling
          String? filePath = resumeFile.path;
          if (filePath != null) {
            print('Uploading native file from path: $filePath');
            request.files.add(
              await http.MultipartFile.fromPath('file', filePath),
            );
          } else {
            throw Exception(
              "Resume file path is null. Please upload a valid resume.",
            );
          }
        }

        // Add headers to ensure proper content handling
        request.headers['Accept'] = 'application/json';
        request.headers['Content-Type'] = 'multipart/form-data';

        print('Sending request to server...');

        // Send the request with timeout
        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 45), // Increased timeout
          onTimeout:
              () =>
                  throw TimeoutException(
                    'Connection timed out after 45 seconds',
                  ),
        );

        var response = await http.Response.fromStream(streamedResponse);

        // Print detailed response information
        print('API Response Status: ${response.statusCode}');
        print('API Response Headers: ${response.headers}');
        print(
          'API Response Body: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}',
        );

        if (response.statusCode == 200) {
          try {
            var jsonResponse = jsonDecode(response.body);

            // Return the analysis result
            if (jsonResponse['analysis'] is Map) {
              return jsonResponse['analysis'] as Map<String, dynamic>;
            } else if (jsonResponse['analysis'] is String) {
              // Parse the analysis string into a Map if it's a JSON string
              try {
                return jsonDecode(jsonResponse['analysis'])
                    as Map<String, dynamic>;
              } catch (e) {
                print('Error parsing analysis JSON string: $e');
                return {
                  'error':
                      'Could not parse analysis: ${jsonResponse['analysis']}',
                };
              }
            } else {
              return {'error': 'Invalid analysis format'};
            }
          } catch (e) {
            print('Error parsing response JSON: $e');
            return {'error': 'Failed to parse response: $e'};
          }
        } else if (response.statusCode == 500 && retryCount < maxRetries) {
          // Retry on server error (500)
          print('Server error, retrying (${retryCount + 1}/$maxRetries)...');
          retryCount++;
          await Future.delayed(Duration(seconds: 2)); // Wait before retrying
          continue;
        } else {
          var errorBody = 'No response body';
          try {
            // Try to parse the error response as JSON for more details
            var errorJson = jsonDecode(response.body);
            errorBody = errorJson['error'] ?? response.body;
          } catch (e) {
            errorBody = response.body;
          }

          return {
            'error':
                'Server error: ${response.statusCode}\nDetails: $errorBody',
          };
        }
      } catch (e) {
        if (e is TimeoutException && retryCount < maxRetries) {
          print(
            'Request timed out, retrying (${retryCount + 1}/$maxRetries)...',
          );
          retryCount++;
          await Future.delayed(Duration(seconds: 2)); // Wait before retrying
          continue;
        }

        print('Error during resume analysis: $e');
        return {'error': 'Connection error: $e'};
      }
    }

    // This will be reached if all retries are used up
    return {'error': 'Failed to analyze resume after multiple attempts'};
  }

  // Modified _submitResume to use the resume analyzer and store results in Firestore
  Future<void> _submitResume(Map<String, dynamic> job) async {
    final String jobId = job['id'] as String;
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
      final resumeFile = _resumeFiles[jobId]!;

      if (resumeFile.bytes == null && resumeFile.path == null) {
        throw Exception("Resume file is empty. Please upload a valid resume.");
      }

      // Show a message that analysis is in progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analyzing your resume... This may take a moment.'),
          duration: Duration(seconds: 2),
        ),
      );

      // Use the updated ResumeAnalyzer to analyze the resume
      final analysisResult = await _analyzeResume(resumeFile);

      // Check if there's an error in the result
      if (analysisResult.containsKey('error')) {
        throw Exception(analysisResult['error']);
      }

      // Save analysis results to Firestore with additional metadata
      await _firestore.collection('resume_analysis').add({
        'jobId': jobId,
        'jobTitle': job['jobTitle'],
        'company': job['company'],
        'resumeFileName': resumeFile.name,
        'timestamp': FieldValue.serverTimestamp(),
        'analysis': analysisResult,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Resume analyzed and submitted successfully for ${job['jobTitle']}',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print('Error analyzing resume: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to analyze resume: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
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
        MediaQuery.of(context).size.width > 600 &&
        MediaQuery.of(context).size.width <= 1100;
    final isMobile = MediaQuery.of(context).size.width <= 600;

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
                fontSize: isMobile ? 18 : 24,
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
          // For mobile, add a menu icon
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                // Show drawer or bottom sheet with options
                _showMobileMenu(context);
              },
            ),
          // For tablets and desktops, show these icons
          if (!isMobile) ...[
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.message_outlined, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.account_circle_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ],
      ),
      drawer: isMobile ? _buildDrawer() : null,
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
                    Color.fromARGB(255, 0, 0, 0),
                    Color.fromARGB(255, 10, 20, 30),
                  ], // Dark blue to medium blue gradient
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: isMobile ? 16.0 : 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section
                      _buildHeaderSection(isDesktop),
                      SizedBox(height: 24),

                      // Search and filter section
                      _buildSearchAndFilterSection(isDesktop, isTablet),
                      SizedBox(height: 24),

                      // Toggle view buttons for list and grid
                      if (!isMobile)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.grid_view_rounded,
                                color: _isGridView ? Colors.blue : Colors.grey,
                              ),
                              onPressed:
                                  () => setState(() => _isGridView = true),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.view_list_rounded,
                                color: !_isGridView ? Colors.blue : Colors.grey,
                              ),
                              onPressed:
                                  () => setState(() => _isGridView = false),
                            ),
                          ],
                        ),

                      SizedBox(height: 16),

                      // Jobs listings - use StreamBuilder to get real data
                      StreamBuilder<QuerySnapshot>(
                        stream: _jobsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Colors.blue,
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
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
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Convert snapshot to job openings format
                          List<Map<String, dynamic>> jobs =
                              snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return {'id': doc.id, ...data};
                              }).toList();

                          // Decide which view to show based on device and _isGridView
                          if (isMobile) {
                            // Always show list view on mobile
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: jobs.length,
                              itemBuilder: (context, index) {
                                return _buildListJobCard(jobs[index], index);
                              },
                            );
                          } else if (_isGridView) {
                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isDesktop ? 3 : 2,
                                    childAspectRatio: isDesktop ? 1.2 : 1.1,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: jobs.length,
                              itemBuilder: (context, index) {
                                return _buildGridJobCard(jobs[index]);
                              },
                            );
                          } else {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: jobs.length,
                              itemBuilder: (context, index) {
                                return _buildListJobCard(jobs[index], index);
                              },
                            );
                          }
                        },
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Uploading resume...',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 16,
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

  // Helper to build the correct list job card based on device type
  Widget _buildListJobCard(Map<String, dynamic> job, int index) {
    final String jobId = job['id'] ?? 'Unknown ID';
    final String title = job['jobTitle'] ?? 'Untitled Job';
    final String company = job['company'] ?? 'No Company';
    final String location = job['location'] ?? 'Unknown Location';
    final String salary = job['salary'] ?? 'Not Disclosed';
    final List<dynamic> skills = job['requiredSkills'] ?? [];
    final isMobile = MediaQuery.of(context).size.width <= 600;

    if (isMobile) {
      return Card(
        color: Color(0xFF0E3B69),
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildMobileListJobCard(
            job,
            jobId,
            title,
            company,
            location,
            skills,
          ),
        ),
      );
    } else {
      return Card(
        color: Color(0xFF0E3B69),
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildDesktopListJobCard(
            job,
            jobId,
            title,
            company,
            location,
            salary,
            skills,
          ),
        ),
      );
    }
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

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color.fromARGB(255, 2, 4, 7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  title: Text(
                    'Notifications',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(),
                ),
                ListTile(
                  leading: Icon(Icons.message_outlined, color: Colors.white),
                  title: Text(
                    'Messages',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(),
                ),
                ListTile(
                  leading: Icon(
                    Icons.account_circle_outlined,
                    color: Colors.white,
                  ),
                  title: Text(
                    'Profile',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(),
                ),
                ListTile(
                  leading: Icon(Icons.settings_outlined, color: Colors.white),
                  title: Text(
                    'Settings',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(),
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
          // Drawer header with logo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.work_outline, color: Color(0xFFFFD700), size: 28),
                SizedBox(width: 12),
                Text(
                  'JobScope',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white24),
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
    final isMobile = MediaQuery.of(context).size.width <= 600;

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
                    'Find Your Dream Job',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 24 : 32,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Browse through hundreds of job listings and find the perfect match for your skills and career goals.',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[300],
                      fontSize: isMobile ? 14 : 16,
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
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: isMobile ? 14 : 16),
      label: Text(
        label,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: isMobile ? 10 : 12,
        ),
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
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          isMobile
              ? Column(
                children: [
                  // Search field
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search jobs, skills, or companies',
                      hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  // Category dropdown
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Color(0xFF0E3B69),
                        value: _selectedCategory,
                        items:
                            _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value ?? 'All';
                          });
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        isExpanded: true,
                      ),
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search jobs, skills, or companies',
                        hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: Color(0xFF0E3B69),
                          value: _selectedCategory,
                          items:
                              _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value ?? 'All';
                            });
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }

  // Grid view: pass full job
  Widget _buildGridJobCard(Map<String, dynamic> job) {
    final String jobId = job['id'] ?? 'Unknown ID';
    final String title = job['jobTitle'] ?? 'Untitled Job';
    final String company = job['company'] ?? 'No Company';
    final String location = job['location'] ?? 'Unknown Location';
    final List<dynamic> skills = job['requiredSkills'] ?? [];
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Color(0xFF0E3B69),
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
          hoverColor: Color(0xFFFFD700).withOpacity(0.05),
          splashColor: Color(0xFFFFD700).withOpacity(0.1),
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
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      company.isNotEmpty ? company[0].toUpperCase() : 'C',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  company,
                  style: GoogleFonts.montserrat(
                    color: Colors.grey[300],
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey[400],
                      size: isMobile ? 14 : 16,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.montserrat(
                          color: Colors.grey[400],
                          fontSize: isMobile ? 11 : 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        skills
                            .take(3)
                            .map(
                              (skill) => Chip(
                                label: Text(
                                  skill.toString(),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: isMobile ? 10 : 11,
                                  ),
                                ),
                                backgroundColor: Colors.blue.withOpacity(0.2),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                  ),
                ),
                SizedBox(height: 16),
                // Separate Upload and Submit buttons
                ElevatedButton(
                  onPressed: () => _pickFile(jobId),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Upload Resume',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed:
                      _resumeFiles[jobId] == null
                          ? null
                          : () => _submitResume(job),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                  ),
                  child: Text(
                    'Submit Resume',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
                if (_resumeFiles[jobId] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      'File: ${_resumeFiles[jobId]!.name}',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontSize: isMobile ? 10 : 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileListJobCard(
    Map<String, dynamic> job,
    String jobId,
    String title,
    String company,
    String location,
    List<dynamic> skills,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and logo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company logo placeholder
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  company.isNotEmpty ? company[0].toUpperCase() : 'C',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    company,
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey[400],
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.montserrat(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Skills chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              skills
                  .take(3)
                  .map(
                    (skill) => Chip(
                      label: Text(
                        skill.toString(),
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
        ),

        SizedBox(height: 16),

        // Separate Upload and Submit buttons
        ElevatedButton(
          onPressed: () => _pickFile(jobId),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            minimumSize: Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Upload Resume',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _resumeFiles[jobId] == null ? null : () => _submitResume(job),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            minimumSize: Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: Colors.grey.withOpacity(0.5),
          ),
          child: Text(
            'Submit Resume',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        if (_resumeFiles[jobId] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              'File: ${_resumeFiles[jobId]!.name}',
              style: GoogleFonts.poppins(color: Colors.green, fontSize: 10),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopListJobCard(
    Map<String, dynamic> job,
    String jobId,
    String title,
    String company,
    String location,
    String salary,
    List<dynamic> skills,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company logo placeholder
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              company.isNotEmpty ? company[0].toUpperCase() : 'C',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    company,
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey[400],
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    location,
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.attach_money, color: Colors.grey[400], size: 14),
                  SizedBox(width: 4),
                  Text(
                    salary,
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
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
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        Column(
          children: [
            ElevatedButton(
              onPressed: () => _pickFile(jobId),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                minimumSize: Size(130, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Upload Resume',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  _resumeFiles[jobId] == null ? null : () => _submitResume(job),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                minimumSize: Size(130, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey.withOpacity(0.5),
              ),
              child: Text(
                'Submit',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
            ),
            if (_resumeFiles[jobId] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  'File: ${_resumeFiles[jobId]!.name}',
                  style: GoogleFonts.poppins(color: Colors.green, fontSize: 10),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Details dialog
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

    final isMobile = MediaQuery.of(context).size.width <= 600;

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
              maxWidth: isMobile ? double.infinity : 800,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              children: [
                // Job header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(0xFF0D3B66),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 18 : 24,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            color: Colors.blue[200],
                            size: isMobile ? 16 : 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            company,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.blue[200],
                            size: isMobile ? 16 : 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            location,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildHighlightItem(Icons.work, employmentType),
                          _buildHighlightItem(
                            Icons.trending_up,
                            experienceLevel,
                          ),
                          _buildHighlightItem(Icons.attach_money, salary),
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
                        Text(
                          'Job Description',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 16 : 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Required Skills',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 16 : 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              skills
                                  .map(
                                    (skill) => Chip(
                                      label: Text(
                                        skill.toString(),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: isMobile ? 12 : 14,
                                        ),
                                      ),
                                      backgroundColor: Colors.blue.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        SizedBox(height: 24),
                        _buildDetailRow('Employment Type', employmentType),
                        _buildDetailRow('Experience', experienceLevel),
                        _buildDetailRow('Salary', salary),
                        _buildDetailRow('Location', location),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _pickFile(jobId),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Upload Resume',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _resumeFiles[jobId] == null
                                        ? null
                                        : () => _submitResume(job),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  disabledBackgroundColor: Colors.grey
                                      .withOpacity(0.5),
                                ),
                                child: Text(
                                  'Submit Application',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (_resumeFiles[jobId] != null)
                          Center(
                            child: Text(
                              'File: ${_resumeFiles[jobId]!.name}',
                              style: GoogleFonts.poppins(
                                color: Colors.green,
                                fontSize: isMobile ? 12 : 14,
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
        );
      },
    );
  }

  Widget _buildHighlightItem(IconData icon, String text) {
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[200], size: isMobile ? 20 : 24),
          SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: isMobile ? 12 : 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 100 : 150,
            child: Text(
              label + ':',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
