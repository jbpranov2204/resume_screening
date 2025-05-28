import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class JobDescriptionPage extends StatefulWidget {
  final String? jobId; // For editing existing jobs
  final bool viewOnly; // To control whether the page is in view-only mode

  const JobDescriptionPage({Key? key, this.jobId, this.viewOnly = false})
    : super(key: key);

  @override
  _JobDescriptionPageState createState() => _JobDescriptionPageState();
}

class _JobDescriptionPageState extends State<JobDescriptionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Document ID for the current job (if editing)
  String? _jobDocumentId;

  // Form fields
  String _jobTitle = '';
  String _company = '';
  String _location = '';
  String _jobDescription = '';
  String _salary = '';
  String _experienceLevel = 'Entry Level';
  String _employmentType = 'Full-time';
  List<String> _selectedSkills = [];
  bool _isJobPosted = false;
  bool _isLoading = false;

  // Available options
  final List<String> _availableSkills = [
    'Flutter',
    'Dart',
    'React',
    'React Native',
    'JavaScript',
    'TypeScript',
    'HTML/CSS',
    'Node.js',
    'Express.js',
    'Python',
    'Django',
    'Flask',
    'Java',
    'Spring Boot',
    'Kotlin',
    'Swift',
    'iOS Development',
    'Android Development',
    'C#',
    '.NET',
    'PHP',
    'Laravel',
    'Ruby',
    'Ruby on Rails',
    'SQL',
    'MySQL',
    'PostgreSQL',
    'MongoDB',
    'Firebase',
    'AWS',
    'Docker',
    'Kubernetes',
    'CI/CD',
    'Git',
    'DevOps',
    'Machine Learning',
    'TensorFlow',
    'PyTorch',
    'Data Analysis',
    'Data Science',
    'Big Data',
    'Hadoop',
    'Spark',
    'UI/UX Design',
    'Figma',
    'Adobe XD',
    'Product Management',
    'Agile',
    'Scrum',
    'Technical Writing',
  ];

  final List<String> _experienceLevels = [
    'Entry Level',
    'Junior',
    'Mid-Level',
    'Senior',
    'Lead',
    'Manager',
  ];

  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.jobId != null) {
      _jobDocumentId = widget.jobId;
      _loadJobFromFirestore(widget.jobId!);
    }
  }

  Future<void> _saveJobToFirestore() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_selectedSkills.isEmpty || _selectedSkills.length > 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select between 1-9 skills'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final jobData = {
        'jobTitle': _jobTitle,
        'company': _company,
        'location': _location,
        'salary': _salary,
        'experienceLevel': _experienceLevel,
        'employmentType': _employmentType,
        'requiredSkills': _selectedSkills,
        'jobDescription': _jobDescription,
        'postedBy': userId,
        'postedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      if (_jobDocumentId != null) {
        await _firestore.collection('jobs').doc(_jobDocumentId).update(jobData);
      } else {
        final docRef = await _firestore.collection('jobs').add(jobData);
        _jobDocumentId = docRef.id;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _jobDocumentId != null ? 'Job updated!' : 'Job posted!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _isJobPosted = true);
      _tabController.animateTo(1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadJobFromFirestore(String jobId) async {
    setState(() => _isLoading = true);

    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _jobTitle = data['jobTitle'] ?? '';
          _company = data['company'] ?? '';
          _location = data['location'] ?? '';
          _salary = data['salary'] ?? '';
          _experienceLevel = data['experienceLevel'] ?? 'Entry Level';
          _employmentType = data['employmentType'] ?? 'Full-time';
          _jobDescription = data['jobDescription'] ?? '';
          _selectedSkills = List<String>.from(data['requiredSkills'] ?? []);
          _isJobPosted = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load job: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Check if we're on a mobile device
  bool _isMobileView(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobileView(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        centerTitle: false,
        title: Text(
          widget.viewOnly
              ? 'Job Details'
              : (_jobDocumentId != null
                  ? 'Edit Job Posting'
                  : 'Create New Job Posting'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.business_center_outlined,
              color: Colors.white70,
              size: 22,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg3.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.75),
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 900,
            ),
            child: Container(
              margin: EdgeInsets.symmetric(
                vertical: isMobile ? 10 : 20,
                horizontal: isMobile ? 8 : 16,
              ),
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
                border: Border.all(
                  color: Colors.grey.shade800.withOpacity(0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                          strokeWidth: 3,
                        ),
                      )
                      : isMobile
                      ? (widget.viewOnly
                          ? _buildMobileJobDetailsView()
                          : _buildMobileJobDetailsTab())
                      : (widget.viewOnly
                          ? _buildWebJobDetailsView()
                          : _buildJobDetailsTab()),
            ),
          ),
        ),
      ),
    );
  }

  // Mobile-specific layout
  Widget _buildMobileJobDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Job Title Field
            _buildMobileTextField(
              label: 'Job Title',
              hint: 'e.g., Senior Flutter Developer',
              initialValue: _jobTitle,
              onSaved: (value) => _jobTitle = value ?? '',
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Company Field
            _buildMobileTextField(
              label: 'Company',
              hint: 'e.g., Tech Solutions Inc.',
              initialValue: _company,
              onSaved: (value) => _company = value ?? '',
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Location Field
            _buildMobileTextField(
              label: 'Location',
              hint: 'e.g., New York, NY (or Remote)',
              initialValue: _location,
              onSaved: (value) => _location = value ?? '',
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Salary Field
            _buildMobileTextField(
              label: 'Salary Range (Optional)',
              hint: 'e.g., 80,000 - 100,000',
              initialValue: _salary,
              onSaved: (value) => _salary = value ?? '',
            ),
            const SizedBox(height: 16),

            // Experience Level Dropdown
            _buildMobileDropdownField(
              label: 'Experience Level',
              value: _experienceLevel,
              items: _experienceLevels,
              onChanged: (value) => setState(() => _experienceLevel = value!),
            ),
            const SizedBox(height: 16),

            // Employment Type Dropdown
            _buildMobileDropdownField(
              label: 'Employment Type',
              value: _employmentType,
              items: _employmentTypes,
              onChanged: (value) => setState(() => _employmentType = value!),
            ),
            const SizedBox(height: 20),

            // Job Description Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job Description',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: TextFormField(
                    maxLines: 5,
                    initialValue: _jobDescription,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter detailed job description here...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => _jobDescription = value ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Required Skills Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Required Skills',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_selectedSkills.length}/9',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color:
                            _selectedSkills.length > 9
                                ? Colors.red
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Selected skills chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _selectedSkills
                          .map(
                            (skill) => Chip(
                              label: Text(
                                skill,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: Colors.blue,
                              deleteIconColor: Colors.black87,
                              onDeleted:
                                  () => setState(
                                    () => _selectedSkills.remove(skill),
                                  ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 12),

                // Mobile skills selection
                _buildMobileSkillsSelector(),
              ],
            ),
            const SizedBox(height: 24),

            // Post Job Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveJobToFirestore,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.publish),
                    const SizedBox(width: 8),
                    Text(
                      _jobDocumentId != null ? 'Update Job' : 'Post Job',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Mobile skills selector with search functionality
  Widget _buildMobileSkillsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap to select skills (max 9)',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _availableSkills.length,
            itemBuilder: (context, index) {
              final skill = _availableSkills[index];
              final isSelected = _selectedSkills.contains(skill);

              return Container(
                margin: EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    skill,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.blue : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  trailing:
                      isSelected
                          ? Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 18,
                          )
                          : Icon(
                            Icons.add_circle_outline,
                            color: Colors.grey,
                            size: 18,
                          ),
                  onTap:
                      () => setState(() {
                        if (isSelected) {
                          _selectedSkills.remove(skill);
                        } else if (_selectedSkills.length < 9) {
                          _selectedSkills.add(skill);
                        }
                      }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Mobile text field widget
  Widget _buildMobileTextField({
    required String label,
    required String hint,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: TextFormField(
            initialValue: initialValue,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            validator: validator,
            onSaved: onSaved,
          ),
        ),
      ],
    );
  }

  // Mobile dropdown field widget
  Widget _buildMobileDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.grey.shade900,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.blue,
                size: 20,
              ),
              items:
                  items.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Mobile view-only layout - for viewing job details
  Widget _buildMobileJobDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job header with title, company and location
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _jobTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _company,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildMobileDetailRow(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: _location,
                ),
                _buildMobileDetailRow(
                  icon: Icons.attach_money,
                  title: 'Salary',
                  value: _salary.isNotEmpty ? _salary : 'Not specified',
                ),
                _buildMobileDetailRow(
                  icon: Icons.work_history_outlined,
                  title: 'Experience',
                  value: _experienceLevel,
                ),
                _buildMobileDetailRow(
                  icon: Icons.timer_outlined,
                  title: 'Employment Type',
                  value: _employmentType,
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Required Skills
          Text(
            'Required Skills',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _selectedSkills.map((skill) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      skill,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blue.shade300,
                      ),
                    ),
                  );
                }).toList(),
          ),

          SizedBox(height: 24),

          // Job Description
          Text(
            'Job Description',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Text(
              _jobDescription,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: 32),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Implement apply functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Application feature coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send),
                  const SizedBox(width: 8),
                  Text(
                    'Apply for Job',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper for mobile view item row
  Widget _buildMobileDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Web view-only layout - for viewing job details
  Widget _buildWebJobDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with job title and company
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.work_outline, color: Colors.blue, size: 32),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _jobTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _company,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              // Apply button
              ElevatedButton(
                onPressed: () {
                  // Implement apply functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Application feature coming soon!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.send),
                    const SizedBox(width: 8),
                    Text(
                      'Apply for Job',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 32),

          // Job details in a grid
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildWebDetailItem(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    value: _location,
                  ),
                ),
                Container(height: 50, width: 1, color: Colors.grey.shade800),
                Expanded(
                  child: _buildWebDetailItem(
                    icon: Icons.attach_money,
                    title: 'Salary',
                    value: _salary.isNotEmpty ? _salary : 'Not specified',
                  ),
                ),
                Container(height: 50, width: 1, color: Colors.grey.shade800),
                Expanded(
                  child: _buildWebDetailItem(
                    icon: Icons.work_history_outlined,
                    title: 'Experience',
                    value: _experienceLevel,
                  ),
                ),
                Container(height: 50, width: 1, color: Colors.grey.shade800),
                Expanded(
                  child: _buildWebDetailItem(
                    icon: Icons.timer_outlined,
                    title: 'Employment Type',
                    value: _employmentType,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Required Skills section
          Text(
            'Required Skills',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                _selectedSkills.map((skill) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      skill,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade300,
                      ),
                    ),
                  );
                }).toList(),
          ),

          SizedBox(height: 32),

          // Job Description section
          Text(
            'Job Description',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Text(
              _jobDescription,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white,
                height: 1.6,
              ),
            ),
          ),

          SizedBox(height: 40),

          // Bottom info section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade300, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Apply now to join our team! We review applications within 3-5 business days.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper for web view item detail
  Widget _buildWebDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade300, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Desktop/web layout (original)
  Widget _buildJobDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Information',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Job Title Field
            _buildHoverableContainer(
              child: _buildTextField(
                label: 'Job Title',
                hint: 'e.g., Senior Flutter Developer',
                initialValue: _jobTitle,
                onSaved: (value) => _jobTitle = value ?? '',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Company Field
            _buildHoverableContainer(
              child: _buildTextField(
                label: 'Company',
                hint: 'e.g., Tech Solutions Inc.',
                initialValue: _company,
                onSaved: (value) => _company = value ?? '',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Location Field
            _buildHoverableContainer(
              child: _buildTextField(
                label: 'Location',
                hint: 'e.g., New York, NY (or Remote)',
                initialValue: _location,
                onSaved: (value) => _location = value ?? '',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Salary Field
            _buildHoverableContainer(
              child: _buildTextField(
                label: 'Salary Range (Optional)',
                hint: 'e.g., 80,000 - 100,000',
                initialValue: _salary,
                onSaved: (value) => _salary = value ?? '',
              ),
            ),
            const SizedBox(height: 16),

            // Experience Level Dropdown
            _buildHoverableContainer(
              child: _buildDropdownField(
                label: 'Experience Level',
                value: _experienceLevel,
                items: _experienceLevels,
                onChanged: (value) => setState(() => _experienceLevel = value!),
              ),
            ),
            const SizedBox(height: 16),

            // Employment Type Dropdown
            _buildHoverableContainer(
              child: _buildDropdownField(
                label: 'Employment Type',
                value: _employmentType,
                items: _employmentTypes,
                onChanged: (value) => setState(() => _employmentType = value!),
              ),
            ),
            const SizedBox(height: 24),

            // Job Description Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job Description',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: TextFormField(
                    maxLines: 6,
                    initialValue: _jobDescription,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter detailed job description here...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => _jobDescription = value ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Required Skills Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Required Skills (Select up to 9)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_selectedSkills.length}/9',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color:
                            _selectedSkills.length > 9
                                ? Colors.red
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selected skills chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _selectedSkills
                          .map(
                            (skill) => Chip(
                              label: Text(
                                skill,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: Colors.blue,
                              deleteIconColor: Colors.black87,
                              onDeleted:
                                  () => setState(
                                    () => _selectedSkills.remove(skill),
                                  ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),

                // Available skills grid
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _availableSkills.length,
                    itemBuilder: (context, index) {
                      final skill = _availableSkills[index];
                      final isSelected = _selectedSkills.contains(skill);

                      return InkWell(
                        onTap:
                            () => setState(() {
                              if (isSelected) {
                                _selectedSkills.remove(skill);
                              } else if (_selectedSkills.length < 9) {
                                _selectedSkills.add(skill);
                              }
                            }),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.blue : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade700,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              skill,
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 12,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Post Job Button
            Center(
              child: _buildHoverableContainer(
                borderRadius: BorderRadius.circular(30),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveJobToFirestore,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.blue.withOpacity(0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.publish),
                      const SizedBox(width: 12),
                      Text(
                        _jobDocumentId != null ? 'Update Job' : 'Post Job',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Existing web view methods
  Widget _buildTextField({
    required String label,
    required String hint,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            initialValue: initialValue,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.blue.withOpacity(0.7),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: validator,
            onSaved: onSaved,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.grey.shade900,
              style: GoogleFonts.poppins(color: Colors.white),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
              items:
                  items.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoverableContainer({
    required Widget child,
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
