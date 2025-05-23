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
import 'package:dio/dio.dart'; // Add this import for Dio

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
    // Show immediate feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing your resume...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Log file information for debugging
      print(
        'Analyzing resume: ${resumeFile.name}, Size: ${resumeFile.size} bytes',
      );

      // Create Dio instance with base options - increasing timeouts significantly
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://resume-2kvb.onrender.com/',
          connectTimeout: Duration(
            seconds: 60,
          ), // Increased from 15 to 60 seconds
          receiveTimeout: Duration(
            seconds: 60,
          ), // Increased from 15 to 60 seconds
          sendTimeout: Duration(
            seconds: 60,
          ), // Added send timeout of 60 seconds
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // Show a more informative message that the server might be slow
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connecting to resume analysis server. This may take a moment...',
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // Create FormData object
      FormData formData;

      if (kIsWeb) {
        // Web platform handling
        final bytes = resumeFile.bytes;
        final filename = resumeFile.name;
        if (bytes != null) {
          print('Uploading web file: $filename, ${bytes.length} bytes');
          formData = FormData.fromMap({
            'file': MultipartFile.fromBytes(bytes, filename: filename),
          });
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
          formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(
              filePath,
              filename: resumeFile.name,
            ),
          });
        } else {
          throw Exception(
            "Resume file path is null. Please upload a valid resume.",
          );
        }
      }

      print('Sending request to server with longer timeout...');

      // Send the request with Dio
      final response = await dio.post(
        '/',
        data: formData,
        onSendProgress: (sent, total) {
          print('Upload progress: ${(sent / total * 100).toStringAsFixed(2)}%');
        },
      );

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Return the analysis result
        if (data['analysis'] is Map) {
          return data['analysis'] as Map<String, dynamic>;
        } else if (data['analysis'] is String) {
          // Parse the analysis string into a Map if it's a JSON string
          try {
            return jsonDecode(data['analysis']) as Map<String, dynamic>;
          } catch (e) {
            print('Error parsing analysis JSON string: $e');
            return {'error': 'Could not parse analysis: ${data['analysis']}'};
          }
        } else {
          return {'error': 'Invalid analysis format'};
        }
      } else {
        return {
          'error':
              'Server error: ${response.statusCode}\nDetails: ${response.data}',
        };
      }
    } on DioException catch (e) {
      print('Dio error during resume analysis: ${e.message}');
      String errorMsg = 'Network error';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMsg =
            'The server is taking too long to respond. Please try again later.';
      } else if (e.response != null) {
        errorMsg = 'Server error: ${e.response?.statusCode}';
      }

      return {'error': errorMsg};
    } catch (e) {
      print('Error during resume analysis: $e');
      return {'error': 'Error: $e'};
    }
  }

  // Modified _submitResume to use the updated resume analyzer
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

      // Use the updated resume analyzer with Dio
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
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error analyzing resume: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to analyze resume: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E3B69), Color(0xFF0A2A4D)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 6),
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
                // Company logo with glassmorphism effect
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      company.isNotEmpty ? company[0].toUpperCase() : 'C',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
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
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      color: Color(0xFFFFD700),
                      size: isMobile ? 14 : 16,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        company,
                        style: GoogleFonts.montserrat(
                          color: Colors.grey[300],
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFFFD700),
                      size: isMobile ? 14 : 16,
                    ),
                    SizedBox(width: 6),
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
                              (skill) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withOpacity(0.3),
                                      Colors.indigo.withOpacity(0.2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  skill.toString(),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: isMobile ? 10 : 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                SizedBox(height: 16),
                // Upload Resume button with animated gradient
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _pickFile(jobId),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Upload Resume',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Submit Resume button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [Colors.green[700]!, Colors.green[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed:
                        _resumeFiles[jobId] == null
                            ? null
                            : () => _submitResume(job),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      shadowColor: Colors.transparent,
                      minimumSize: Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Submit',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_resumeFiles[jobId] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[300],
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_resumeFiles[jobId]!.name}',
                            style: GoogleFonts.poppins(
                              color: Colors.green[300],
                              fontSize: isMobile ? 10 : 12,
                            ),
                            overflow: TextOverflow.ellipsis,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E3B69), Color(0xFF0A2A4D)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showJobDetailsDialog(job),
          borderRadius: BorderRadius.circular(16),
          splashColor: Color(0xFFFFD700).withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and logo with enhanced design
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company logo with glassmorphism effect
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          company.isNotEmpty ? company[0].toUpperCase() : 'C',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
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
                              letterSpacing: 0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.business_outlined,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  company,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                              SizedBox(width: 6),
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

                // Skills chips with better styling
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      skills
                          .take(3)
                          .map(
                            (skill) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.3),
                                    Colors.indigo.withOpacity(0.2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                skill.toString(),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),

                SizedBox(height: 16),

                // Action buttons with gradient effect
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Colors.blue[700]!, Colors.blue[500]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _pickFile(jobId),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Upload',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Colors.green[700]!, Colors.green[500]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed:
                              _resumeFiles[jobId] == null
                                  ? null
                                  : () => _submitResume(job),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.grey.withOpacity(
                              0.3,
                            ),
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Submit',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_resumeFiles[jobId] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[300],
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_resumeFiles[jobId]!.name}',
                            style: GoogleFonts.poppins(
                              color: Colors.green[300],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  // Placeholder for desktop list job card
  Widget _buildDesktopListJobCard(
    Map<String, dynamic> job,
    String jobId,
    String title,
    String company,
    String location,
    String salary,
    List<dynamic> skills,
  ) {
    // Reuse mobile list card for desktop layout
    return _buildMobileListJobCard(
      job,
      jobId,
      title,
      company,
      location,
      skills,
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
    final companyInitial = company.isNotEmpty ? company[0].toUpperCase() : 'C';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Job Details',
      barrierColor: Colors.black87,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container(); // Not used, we'll use transitionBuilder instead
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuint,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: 24,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 800,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D2645), Color(0xFF071630)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Background decorative elements
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.blueAccent.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.8],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -100,
                        left: -50,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.purpleAccent.withOpacity(0.07),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.8],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top section with header and image
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF0A3166), Color(0xFF072547)],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top bar with close button
                                Padding(
                                  padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(
                                            0xFFFFD700,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          border: Border.all(
                                            color: Color(
                                              0xFFFFD700,
                                            ).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'FEATURED',
                                              style: GoogleFonts.montserrat(
                                                color: Color(0xFFFFD700),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.star,
                                              color: Color(0xFFFFD700),
                                              size: 12,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Spacer(),
                                      IconButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        icon: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            size: 20,
                                          ),
                                        ),
                                        splashRadius: 24,
                                      ),
                                    ],
                                  ),
                                ),

                                // Job title and company info
                                Padding(
                                  padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Company logo with 3D effect
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withOpacity(0.25),
                                              Colors.white.withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 10,
                                              offset: Offset(0, -3),
                                              spreadRadius: -2,
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            companyInitial,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 28,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0, 3),
                                                  blurRadius: 6,
                                                  color: Colors.black
                                                      .withOpacity(0.4),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 20),

                                      // Job title and metadata
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: GoogleFonts.montserrat(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isMobile ? 20 : 24,
                                                height: 1.2,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.business_outlined,
                                                  color: Color(0xFFFFD700),
                                                  size: 16,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  company,
                                                  style: GoogleFonts.montserrat(
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 5),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  color: Color(0xFFFFD700),
                                                  size: 16,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  location,
                                                  style: GoogleFonts.montserrat(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Employment details with pills
                                Container(
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(30),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildInfoPill(
                                        icon: Icons.work_outline,
                                        label: "Type",
                                        value: employmentType,
                                        color: Colors.blue[400]!,
                                      ),
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                      _buildInfoPill(
                                        icon: Icons.trending_up,
                                        label: "Experience",
                                        value: experienceLevel,
                                        color: Colors.purple[300]!,
                                      ),
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                      _buildInfoPill(
                                        icon: Icons.attach_money,
                                        label: "Salary",
                                        value: salary,
                                        color: Colors.green[400]!,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Job details with custom scrollbar
                          Expanded(
                            child: Theme(
                              data: ThemeData(
                                scrollbarTheme: ScrollbarThemeData(
                                  thumbColor: MaterialStateProperty.all(
                                    Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              child: Scrollbar(
                                thickness: 6,
                                radius: Radius.circular(3),
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader(
                                        title: "Job Description",
                                        icon: Icons.description_outlined,
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          description,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 15,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 24),

                                      _buildSectionHeader(
                                        title: "Required Skills",
                                        icon: Icons.lightbulb_outline,
                                      ),
                                      SizedBox(height: 16),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children:
                                            skills
                                                .map(
                                                  (skill) => _buildSkillChip(
                                                    skill.toString(),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                      SizedBox(height: 24),

                                      _buildSectionHeader(
                                        title: "Job Details",
                                        icon: Icons.info_outline,
                                      ),
                                      SizedBox(height: 16),
                                      _buildJobDetail(
                                        iconData: Icons.work_outline,
                                        label: "Employment Type",
                                        value: employmentType,
                                      ),
                                      _buildJobDetail(
                                        iconData: Icons.timeline,
                                        label: "Experience Level",
                                        value: experienceLevel,
                                      ),
                                      _buildJobDetail(
                                        iconData: Icons.attach_money,
                                        label: "Salary",
                                        value: salary,
                                      ),
                                      _buildJobDetail(
                                        iconData: Icons.location_on_outlined,
                                        label: "Location",
                                        value: location,
                                      ),
                                      SizedBox(height: 30),

                                      // Application section
                                      _buildSectionHeader(
                                        title: "Apply for this job",
                                        icon: Icons.send_outlined,
                                      ),
                                      SizedBox(height: 16),

                                      // Resume status indicator
                                      if (_resumeFiles[jobId] != null)
                                        _buildResumeStatusCard(
                                          _resumeFiles[jobId]!,
                                        ),

                                      SizedBox(height: 16),

                                      // Action buttons with gradients
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.blue[700]!,
                                                    Colors.blue[400]!,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.blue
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton(
                                                onPressed:
                                                    () => _pickFile(jobId),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.upload_file_rounded,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Upload',
                                                      style:
                                                          GoogleFonts.montserrat(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                gradient:
                                                    _resumeFiles[jobId] == null
                                                        ? LinearGradient(
                                                          colors: [
                                                            Colors.grey[700]!,
                                                            Colors.grey[600]!,
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end:
                                                              Alignment
                                                                  .bottomRight,
                                                        )
                                                        : LinearGradient(
                                                          colors: [
                                                            Colors.green[700]!,
                                                            Colors.green[500]!,
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end:
                                                              Alignment
                                                                  .bottomRight,
                                                        ),
                                                boxShadow:
                                                    _resumeFiles[jobId] == null
                                                        ? []
                                                        : [
                                                          BoxShadow(
                                                            color: Colors.green
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            blurRadius: 8,
                                                            offset: Offset(
                                                              0,
                                                              4,
                                                            ),
                                                          ),
                                                        ],
                                              ),
                                              child: ElevatedButton(
                                                onPressed:
                                                    _resumeFiles[jobId] == null
                                                        ? null
                                                        : () =>
                                                            _submitResume(job),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  disabledForegroundColor:
                                                      Colors.white.withOpacity(
                                                        0.5,
                                                      ),
                                                  disabledBackgroundColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.send_rounded),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Submit',
                                                      style:
                                                          GoogleFonts.montserrat(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFFFFD700), size: 18),
        SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.indigo.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Text(
        skill,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildJobDetail({
    required IconData iconData,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: Color(0xFFFFD700), size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeStatusCard(PlatformFile file) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.2),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.description, color: Colors.blue[300], size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Resume Ready",
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  file.name,
                  style: GoogleFonts.poppins(
                    color: Colors.blue[200],
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green[400], size: 24),
        ],
      ),
    );
  }
}
