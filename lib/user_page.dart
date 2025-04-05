import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class JobOpeningsPage extends StatefulWidget {
  @override
  _JobOpeningsPageState createState() => _JobOpeningsPageState();
}

class _JobOpeningsPageState extends State<JobOpeningsPage> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, PlatformFile?> _resumeFiles = {};
  bool _isLoading = false;

  // Sample job openings data
  final List<Map<String, dynamic>> _jobOpenings = [
    {
      'id': '1',
      'title': 'Flutter Developer',
      'company': 'Tech Solutions Inc.',
      'location': 'New York, NY',
      'salary': '\$80,000 - \$100,000',
      'experienceLevel': 'Mid-Level',
      'employmentType': 'Full-time',
      'description':
          'We are seeking a skilled Flutter Developer to join our team. You will be responsible for developing and maintaining mobile applications using Flutter. The ideal candidate has experience with Dart and Firebase, and is comfortable working in an Agile environment.',
      'skills': ['Flutter', 'Dart', 'Firebase', 'Git', 'REST API'],
    },
    {
      'id': '2',
      'title': 'Machine Learning Engineer',
      'company': 'AI Innovations',
      'location': 'San Francisco, CA',
      'salary': '\$100,000 - \$120,000',
      'experienceLevel': 'Senior',
      'employmentType': 'Contract',
      'description':
          'AI Innovations is looking for a Machine Learning Engineer to design and implement machine learning models. You will work closely with data scientists and software engineers to integrate ML solutions into our products. Experience with TensorFlow and Python is required.',
      'skills': [
        'Python',
        'TensorFlow',
        'Machine Learning',
        'Data Science',
        'PyTorch',
      ],
    },
    {
      'id': '3',
      'title': 'Full Stack Developer',
      'company': 'WebWorks Ltd.',
      'location': 'Remote',
      'salary': '\$90,000 - \$110,000',
      'experienceLevel': 'Senior',
      'employmentType': 'Freelance',
      'description':
          'WebWorks is hiring a Full Stack Developer to build and maintain web applications. You will be responsible for both frontend and backend development. We are looking for someone with experience in JavaScript, React, and Node.js.',
      'skills': ['JavaScript', 'React', 'Node.js', 'MongoDB', 'Express.js'],
    },
    {
      'id': '4',
      'title': 'UI/UX Designer',
      'company': 'Creative Designs',
      'location': 'Chicago, IL',
      'salary': '\$75,000 - \$95,000',
      'experienceLevel': 'Mid-Level',
      'employmentType': 'Full-time',
      'description':
          'Creative Designs is seeking a talented UI/UX Designer to create beautiful and functional user interfaces. You will work closely with product managers and developers to implement your designs. Experience with Figma and Adobe XD is required.',
      'skills': [
        'UI/UX Design',
        'Figma',
        'Adobe XD',
        'Prototyping',
        'User Research',
      ],
    },
    {
      'id': '5',
      'title': 'DevOps Engineer',
      'company': 'Cloud Solutions',
      'location': 'Seattle, WA',
      'salary': '\$110,000 - \$130,000',
      'experienceLevel': 'Senior',
      'employmentType': 'Full-time',
      'description':
          'Cloud Solutions is looking for a DevOps Engineer to improve our infrastructure and deployment processes. You will be responsible for implementing CI/CD pipelines and managing cloud resources. Experience with AWS, Docker, and Kubernetes is required.',
      'skills': ['DevOps', 'AWS', 'Docker', 'Kubernetes', 'CI/CD'],
    },
  ];

  List<Map<String, dynamic>> get _filteredJobOpenings {
    if (_searchController.text.isEmpty) {
      return _jobOpenings;
    }

    final searchQuery = _searchController.text.toLowerCase();

    return _jobOpenings.where((job) {
      bool hasMatchingSkill = false;
      for (String skill in job['skills']) {
        if (skill.toLowerCase().contains(searchQuery)) {
          hasMatchingSkill = true;
          break;
        }
      }

      bool hasMatchingTitle = job['title'].toLowerCase().contains(searchQuery);
      return hasMatchingSkill || hasMatchingTitle;
    }).toList();
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

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Resume submitted and analyzed successfully for ${job['title']} position',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Job Openings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Text(
                  'Welcome to Job Openings!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find your dream job and apply today',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 24),

                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by job title or skills...',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                SizedBox(height: 24),

                // Job listings header
                Text(
                  'Available Positions (${_filteredJobOpenings.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),

                // Job openings list
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredJobOpenings.length,
                    itemBuilder: (context, index) {
                      final job = _filteredJobOpenings[index];
                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: Duration(milliseconds: 300),
                        child: _buildJobTile(job),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildJobTile(Map<String, dynamic> job) {
    String jobId = job['id'];

    return Card(
      color: Colors.grey[850],
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          job['title'],
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          job['company'],
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Location', job['location']),
                _buildDetailRow('Salary', job['salary']),
                _buildDetailRow('Experience Level', job['experienceLevel']),
                _buildDetailRow('Employment Type', job['employmentType']),
                SizedBox(height: 12),
                Text(
                  'Job Description:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  job['description'],
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                SizedBox(height: 12),
                Text(
                  'Required Skills:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (job['skills'] as List<dynamic>).map((skill) {
                        return Chip(
                          label: Text(
                            skill.toString(),
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: Colors.blue.shade800,
                        );
                      }).toList(),
                ),
                SizedBox(height: 16),

                // Resume upload section
                Divider(color: Colors.grey[700]),
                SizedBox(height: 16),
                Text(
                  'Apply for this position:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _pickFile(jobId),
                      child: Text('Choose Resume'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey[700],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _resumeFiles[jobId]?.name ?? 'No file selected',
                        style: TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _submitResume(jobId),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Submit Application',
                      style: GoogleFonts.poppins(fontSize: 16),
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
