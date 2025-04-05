import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class JobDescriptionPage extends StatefulWidget {
  @override
  _JobDescriptionPage createState() => _JobDescriptionPage();
}

class _JobDescriptionPage extends State<JobDescriptionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  String _jobTitle = '';
  String _company = '';
  String _location = '';
  String _jobDescription = '';
  String _salary = '';
  String _experienceLevel = 'Entry Level';
  String _employmentType = 'Full-time';
  
  // Selected skills
  List<String> _selectedSkills = [];
  
  // Job posted status
  bool _isJobPosted = false;
  
  // List of available skills (40+ skills)
  final List<String> _availableSkills = [
    'Flutter', 'Dart', 'React', 'React Native', 'JavaScript', 'TypeScript',
    'HTML/CSS', 'Node.js', 'Express.js', 'Python', 'Django', 'Flask',
    'Java', 'Spring Boot', 'Kotlin', 'Swift', 'iOS Development', 'Android Development',
    'C#', '.NET', 'PHP', 'Laravel', 'Ruby', 'Ruby on Rails',
    'SQL', 'MySQL', 'PostgreSQL', 'MongoDB', 'Firebase', 'AWS',
    'Docker', 'Kubernetes', 'CI/CD', 'Git', 'DevOps', 'Machine Learning',
    'TensorFlow', 'PyTorch', 'Data Analysis', 'Data Science', 'Big Data',
    'Hadoop', 'Spark', 'UI/UX Design', 'Figma', 'Adobe XD',
    'Product Management', 'Agile', 'Scrum', 'Technical Writing'
  ];
  
  // Experience level options
  final List<String> _experienceLevels = [
    'Entry Level', 'Junior', 'Mid-Level', 'Senior', 'Lead', 'Manager'
  ];
  
  // Employment type options
  final List<String> _employmentTypes = [
    'Full-time', 'Part-time', 'Contract', 'Freelance', 'Internship'
  ];
  
  // Sample candidate data
  final List<Map<String, dynamic>> _candidates = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateSampleCandidates();
  }
  
  void _generateSampleCandidates() {
    final List<String> names = [
      'John Smith', 'Emily Johnson', 'Michael Williams', 'Emma Brown',
      'Robert Jones', 'Olivia Davis', 'William Miller', 'Sophia Wilson',
      'James Moore', 'Isabella Taylor'
    ];
    
    final List<String> emails = [
      'john.smith@example.com', 'emily.j@example.com', 'michael.w@example.com',
      'emma.brown@example.com', 'r.jones@example.com', 'olivia.d@example.com',
      'william.m@example.com', 'sophia.w@example.com', 'james.m@example.com',
      'isabella.t@example.com'
    ];
    
    final Random random = Random();
    
    for (int i = 0; i < 10; i++) {
      // Generate random skills for each candidate (between 5-15 skills)
      final int skillCount = random.nextInt(10) + 5;
      final List<String> candidateSkills = [];
      
      final List<String> shuffledSkills = List.from(_availableSkills)..shuffle();
      for (int j = 0; j < skillCount; j++) {
        candidateSkills.add(shuffledSkills[j]);
      }
      
      // Generate random years of experience
      final int yearsOfExperience = random.nextInt(10) + 1;
      
      _candidates.add({
        'name': names[i],
        'email': emails[i],
        'skills': candidateSkills,
        'experience': yearsOfExperience,
        'match': 0.0, // Will be calculated later
        'resume': 'resume_${i + 1}.pdf',
      });
    }
  }
  
  void _calculateMatchPercentages() {
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select required skills first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      for (final candidate in _candidates) {
        final List<String> candidateSkills = candidate['skills'] as List<String>;
        int matchedSkills = 0;
        
        for (final skill in _selectedSkills) {
          if (candidateSkills.contains(skill)) {
            matchedSkills++;
          }
        }
        
        // Calculate match percentage based on required skills
        final double matchPercentage = (matchedSkills / _selectedSkills.length) * 100;
        candidate['match'] = matchPercentage;
      }
      
      // Sort candidates by match percentage (descending)
      _candidates.sort((a, b) => (b['match'] as double).compareTo(a['match'] as double));
    });
  }
  
  void _postJob() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if (_selectedSkills.isEmpty || _selectedSkills.length > 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select between 1-9 skills'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Simulate job posting
      setState(() {
        _isJobPosted = true;
      });
      
      // Calculate match percentages for candidates
      _calculateMatchPercentages();
      
      // Switch to candidates tab
      _tabController.animateTo(1);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
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
          'Post New Job',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(
              icon: Icon(Icons.description_outlined),
              text: 'Job Details',
            ),
            Tab(
              icon: Icon(Icons.people_outline),
              text: 'Candidates',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobDetailsTab(),
          _buildCandidatesTab(),
        ],
      ),
    );
  }

  Widget _buildJobDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
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
            SizedBox(height: 24),
            
            // Job Title Field
            _buildTextField(
              label: 'Job Title',
              hint: 'e.g., Senior Flutter Developer',
              onSaved: (value) => _jobTitle = value ?? '',
              validator: (value) => value!.isEmpty ? 'Job title is required' : null,
            ),
            SizedBox(height: 16),
            
            // Company Field
            _buildTextField(
              label: 'Company',
              hint: 'e.g., Tech Solutions Inc.',
              onSaved: (value) => _company = value ?? '',
              validator: (value) => value!.isEmpty ? 'Company is required' : null,
            ),
            SizedBox(height: 16),
            
            // Location Field
            _buildTextField(
              label: 'Location',
              hint: 'e.g., New York, NY (or Remote)',
              onSaved: (value) => _location = value ?? '',
              validator: (value) => value!.isEmpty ? 'Location is required' : null,
            ),
            SizedBox(height: 16),
            
            // Salary Field
            _buildTextField(
              label: 'Salary Range (Optional)',
              hint: 'e.g., 80,000 - 100,000',
              onSaved: (value) => _salary = value ?? '',
            ),
            SizedBox(height: 16),
            
            // Experience Level Dropdown
            _buildDropdownField(
              label: 'Experience Level',
              value: _experienceLevel,
              items: _experienceLevels,
              onChanged: (value) {
                setState(() {
                  _experienceLevel = value!;
                });
              },
            ),
            SizedBox(height: 16),
            
            // Employment Type Dropdown
            _buildDropdownField(
              label: 'Employment Type',
              value: _employmentType,
              items: _employmentTypes,
              onChanged: (value) {
                setState(() {
                  _employmentType = value!;
                });
              },
            ),
            SizedBox(height: 24),
            
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
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: TextFormField(
                    maxLines: 6,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter detailed job description here...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    validator: (value) => value!.isEmpty ? 'Job description is required' : null,
                    onSaved: (value) => _jobDescription = value ?? '',
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            
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
                        color: _selectedSkills.length > 9 ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Selected skills chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSkills.map((skill) => Chip(
                    label: Text(
                      skill,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: Colors.blue,
                    deleteIconColor: Colors.black87,
                    onDeleted: () {
                      setState(() {
                        _selectedSkills.remove(skill);
                      });
                    },
                  )).toList(),
                ),
                SizedBox(height: 16),
                
                // Available skills grid
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: GridView.builder(
                    padding: EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedSkills.remove(skill);
                            } else if (_selectedSkills.length < 9) {
                              _selectedSkills.add(skill);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade700,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              skill,
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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
            SizedBox(height: 32),
            
            // Post Job Button
            Center(
              child: ElevatedButton(
                onPressed: _postJob,
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
                    Icon(Icons.publish),
                    SizedBox(width: 12),
                    Text(
                      'Post Job',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
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
            Icon(
              Icons.work_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Post a job to see matching candidates',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
              ),
              child: Text('Go to Job Details'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
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
          SizedBox(height: 8),
          Text(
            'Based on the required skills for $_jobTitle',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 24),
          
          // Job skills summary
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
                Text(
                  'Required Skills',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSkills.map((skill) => Chip(
                    label: Text(
                      skill,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: Colors.blue,
                  )).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          
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
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: TextFormField(
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.grey.shade900,
              style: GoogleFonts.poppins(color: Colors.white),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              items: items.map((String item) {
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
    
    Color getMatchColor() {
      if (matchPercentage >= 80) return Colors.green;
      if (matchPercentage >= 50) return Colors.orange;
      return Colors.red;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(16),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: Text(
                candidate['name'].toString().substring(0, 1),
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 16),
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
                  SizedBox(height: 4),
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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: getMatchColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${matchPercentage.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: getMatchColor(),
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey.shade800),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.work_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      '${candidate['experience']} years of experience',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.description_outlined, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Resume: ${candidate['resume']}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Skills',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (candidate['skills'] as List<String>).map((skill) {
                    final bool isMatched = _selectedSkills.contains(skill);
                    return Chip(
                      label: Text(
                        skill,
                        style: GoogleFonts.poppins(
                          color: isMatched ? Colors.black : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: isMatched ? Colors.green : Colors.grey.shade800,
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // View resume action
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade700),
                      ),
                      child: Text('View Resume'),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Contact candidate action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: Text('Contact'),
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
