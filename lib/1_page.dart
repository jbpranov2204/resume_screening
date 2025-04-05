import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class ResumeScreeningPage extends StatefulWidget {
  @override
  _ResumeScreeningPageState createState() => _ResumeScreeningPageState();
}

class _ResumeScreeningPageState extends State<ResumeScreeningPage>
    with SingleTickerProviderStateMixin {
  String? _fileName;
  String _jobDescription = '';
  bool _isProcessing = false;
  double _matchPercentage = 0.0;
  List<String> _matchedSkills = [];
  List<String> _missingSkills = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _fileName = result.files.single.name;
        });
      }
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
  }

  void _analyzeResume() {
    if (_fileName == null || _jobDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload a resume and enter job description')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _matchPercentage = 0.0;
      _matchedSkills = [];
      _missingSkills = [];
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isProcessing = false;
        _matchPercentage = 78.5;
        _matchedSkills = [
          'Flutter',
          'Dart',
          'Firebase',
          'UI/UX Design',
          'Agile Methodology'
        ];
        _missingSkills = ['Machine Learning', 'Python', 'TensorFlow'];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 11, 0, 58),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSXP-e5fI-fDl0csJciATRBP9XkYCRJsPTtRQ&s',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSXP-e5fI-fDl0csJciATRBP9XkYCRJsPTtRQ&s'),
              radius: 18,
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No new notifications')),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Settings clicked')),
                );
              },
            ),
            SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              SizedBox(height: 32),
              _buildTransparentContainer(),
              if (_matchPercentage > 0) ...[
                SizedBox(height: 32),
                _buildResultsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, John!',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Upload a resume and job description to analyze the match',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTransparentContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildResumeUploadCard(),
              SizedBox(height: 24),
              _buildJobDescriptionCard(),
              SizedBox(height: 24),
              _buildAnalyzeButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumeUploadCard() {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(27),
      ),
      child: Padding(
        padding: EdgeInsets.all(27),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Upload Resume',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_file, size: 18),
                      SizedBox(width: 8),
                      Text('Choose File'),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _fileName ?? 'No file selected',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _fileName == null ? Colors.grey : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Supported formats: PDF, DOC, DOCX, TXT',
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

  Widget _buildJobDescriptionCard() {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Job Description',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Paste the job description here...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: EdgeInsets.all(16),
              ),
              style: GoogleFonts.poppins(color: Colors.white),
              onChanged: (value) => setState(() => _jobDescription = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _analyzeResume,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isProcessing
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'ANALYZE RESUME',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Results',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        Card(
          color: Colors.white.withOpacity(0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildMatchScoreIndicator(),
                SizedBox(height: 24),
                _buildSkillsComparison(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchScoreIndicator() {
    final color = _matchPercentage > 70
        ? Colors.green
        : _matchPercentage > 40
            ? Colors.orange
            : Colors.red;

    return Column(
      children: [
        Text(
          'Match Score',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: _matchPercentage / 100,
                strokeWidth: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Column(
              children: [
                Text(
                  '${_matchPercentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _matchPercentage > 70
                      ? 'Strong Match'
                      : _matchPercentage > 40
                          ? 'Moderate Match'
                          : 'Weak Match',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillsComparison() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSkillsList(
            title: 'Matched Skills',
            skills: _matchedSkills,
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildSkillsList(
            title: 'Missing Skills',
            skills: _missingSkills,
            icon: Icons.remove_circle_outline,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsList({
    required String title,
    required List<String> skills,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 12),
        if (skills.isEmpty)
          Text(
            'None',
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...skills.map((skill) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        skill,
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
