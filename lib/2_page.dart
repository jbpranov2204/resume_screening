import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobDescriptionPage extends StatefulWidget {
  final String? jobId; // For editing existing jobs

  const JobDescriptionPage({Key? key, this.jobId}) : super(key: key);

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

  final List<Map<String, dynamic>> _candidates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateSampleCandidates();

    if (widget.jobId != null) {
      _jobDocumentId = widget.jobId;
      _loadJobFromFirestore(widget.jobId!);
    }
  }

  void _generateSampleCandidates() {
    final List<String> names = [
      'John Smith',
      'Emily Johnson',
      'Michael Williams',
      'Emma Brown',
      'Robert Jones',
      'Olivia Davis',
      'William Miller',
      'Sophia Wilson',
      'James Moore',
      'Isabella Taylor',
    ];

    final List<String> emails = [
      'john.smith@example.com',
      'emily.j@example.com',
      'michael.w@example.com',
      'emma.brown@example.com',
      'r.jones@example.com',
      'olivia.d@example.com',
      'william.m@example.com',
      'sophia.w@example.com',
      'james.m@example.com',
      'isabella.t@example.com',
    ];

    final Random random = Random();

    for (int i = 0; i < 10; i++) {
      final int skillCount = random.nextInt(10) + 5;
      final List<String> candidateSkills = [];
      final List<String> shuffledSkills = List.from(_availableSkills)
        ..shuffle();

      for (int j = 0; j < skillCount; j++) {
        candidateSkills.add(shuffledSkills[j]);
      }

      _candidates.add({
        'name': names[i],
        'email': emails[i],
        'skills': candidateSkills,
        'experience': random.nextInt(10) + 1,
        'match': 0.0,
        'resume': 'resume_${i + 1}.pdf',
      });
    }
  }

  void _calculateMatchPercentages() {
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select required skills first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      for (final candidate in _candidates) {
        final List<String> candidateSkills =
            candidate['skills'] as List<String>;
        int matchedSkills = 0;

        for (final skill in _selectedSkills) {
          if (candidateSkills.contains(skill)) {
            matchedSkills++;
          }
        }

        candidate['match'] = (matchedSkills / _selectedSkills.length) * 100;
      }

      _candidates.sort(
        (a, b) => (b['match'] as double).compareTo(a['match'] as double),
      );
    });
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
      _calculateMatchPercentages();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _jobDocumentId != null ? 'Edit Job' : 'Post New Job',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.description_outlined), text: 'Job Details'),
            Tab(icon: Icon(Icons.people_outline), text: 'Candidates'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [_buildJobDetailsTab(), _buildCandidatesTab()],
              ),
    );
  }

  Widget _buildJobDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
            _buildTextField(
              label: 'Job Title',
              hint: 'e.g., Senior Flutter Developer',
              initialValue: _jobTitle,
              onSaved: (value) => _jobTitle = value ?? '',
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Company Field
            _buildTextField(
              label: 'Company',
              hint: 'e.g., Tech Solutions Inc.',
              initialValue: _company,
              onSaved: (value) => _company = value ?? '',
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Location Field
            _buildTextField(
              label: 'Location',
              hint: 'e.g., New York, NY (or Remote)',
              initialValue: _location,
              onSaved: (value) => _location = value ?? '',
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Salary Field
            _buildTextField(
              label: 'Salary Range (Optional)',
              hint: 'e.g., 80,000 - 100,000',
              initialValue: _salary,
              onSaved: (value) => _salary = value ?? '',
            ),
            const SizedBox(height: 16),

            // Experience Level Dropdown
            _buildDropdownField(
              label: 'Experience Level',
              value: _experienceLevel,
              items: _experienceLevels,
              onChanged: (value) => setState(() => _experienceLevel = value!),
            ),
            const SizedBox(height: 16),

            // Employment Type Dropdown
            _buildDropdownField(
              label: 'Employment Type',
              value: _employmentType,
              items: _employmentTypes,
              onChanged: (value) => setState(() => _employmentType = value!),
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
                          childAspectRatio: 2.5,
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidatesTab() {
    if (!_isJobPosted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Post a job to see matching candidates',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              child: const Text('Go to Job Details'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matching Candidates',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on the required skills for $_jobTitle',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Job skills summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Required Skills',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
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
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Candidates list
          ..._candidates.map((candidate) => _buildCandidateCard(candidate)),
        ],
      ),
    );
  }

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
          ),
          child: TextFormField(
            initialValue: initialValue,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
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
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.grey.shade900,
              style: GoogleFonts.poppins(color: Colors.white),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
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

  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
    final double matchPercentage = candidate['match'] as double;
    final Color matchColor =
        matchPercentage >= 80
            ? Colors.green
            : matchPercentage >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: Text(
                candidate['name'].toString().substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    candidate['email'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: matchColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${matchPercentage.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: matchColor,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey.shade800),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${candidate['experience']} years of experience',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Resume: ${candidate['resume']}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Skills',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (candidate['skills'] as List<String>).map((skill) {
                        final isMatched = _selectedSkills.contains(skill);
                        return Chip(
                          label: Text(
                            skill,
                            style: GoogleFonts.poppins(
                              color: isMatched ? Colors.black : Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor:
                              isMatched ? Colors.green : Colors.grey.shade800,
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade700),
                      ),
                      child: const Text('View Resume'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Contact'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
