import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resume_screening/analysis.dart';
import 'package:resume_screening/contact.dart';
import 'package:resume_screening/overview.dart';
import 'package:resume_screening/skills.dart';

// Use the same theme class for consistency
class AppTheme {
  static const Color primaryColor = Color(0xFF3498DB);
  static const Color secondaryColor = Color.fromARGB(255, 0, 21, 255);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E2330);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color successColor = Color(0xFF2ECC71);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color errorColor = Color(0xFFE74C3C);

  static TextStyle headingStyle = GoogleFonts.montserrat(
    color: textPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 20,
  );

  static TextStyle subheadingStyle = GoogleFonts.montserrat(
    color: textPrimary,
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );

  static TextStyle bodyStyle = GoogleFonts.montserrat(
    color: textSecondary,
    fontSize: 14,
  );
}

class CandidateDetailsPage extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String about;
  final String github;
  final String linkedin;
  final String jobTitle;
  final String company;
  final String submittedDate;
  final String experienceSummary;
  final String grade;
  final List<dynamic> improvementSuggestions;
  final List<dynamic> skills;
  final List<dynamic> scoreBreakdown;
  final double score;
  final String likelihood;
  final int probability;
  final String selectionReason;
  final Function(String, String, BuildContext)? sendEmail;

  const CandidateDetailsPage({
    Key? key,
    required this.name,
    required this.email,
    required this.phone,
    required this.about,
    required this.github,
    required this.linkedin,
    required this.jobTitle,
    required this.company,
    required this.submittedDate,
    required this.experienceSummary,
    required this.grade,
    required this.improvementSuggestions,
    required this.skills,
    required this.scoreBreakdown,
    required this.score,
    required this.likelihood,
    required this.probability,
    required this.selectionReason,
    this.sendEmail,
  }) : super(key: key);

  @override
  _CandidateDetailsPageState createState() => _CandidateDetailsPageState();
}

class _CandidateDetailsPageState extends State<CandidateDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 180 && !_isAppBarExpanded) {
      setState(() {
        _isAppBarExpanded = true;
      });
    } else if (_scrollController.offset <= 180 && _isAppBarExpanded) {
      setState(() {
        _isAppBarExpanded = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text(widget.name, style: AppTheme.headingStyle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality can be kept or simplified if needed
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Skills'),
            Tab(text: 'Analysis'),
            Tab(text: 'Contact'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(
            name: widget.name,
            score: widget.score,
            submittedDate: widget.submittedDate,
            experienceSummary: widget.experienceSummary,
            about: widget.about,
            likelihood: widget.likelihood,
            selectionReason: widget.selectionReason,
            scoreBreakdown: widget.scoreBreakdown,
            improvementSuggestions: widget.improvementSuggestions,
            education: [
              
            ]
          ),
          SkillsTab(skills: widget.skills),
          AnalysisTab(
            grade: widget.grade,
            likelihood: widget.likelihood,
            selectionReason: widget.selectionReason,
            probability: widget.probability.toDouble(),
            scoreBreakdown: widget.scoreBreakdown,
          ),
          ContactTab(
            email: widget.email,
            phone: widget.phone,
            linkedin: widget.linkedin,
            github: widget.github,
            company: widget.company,
            jobTitle: widget.jobTitle,
            submittedDate: widget.submittedDate,
            sendEmail: widget.sendEmail,
          ),
        ],
      ),
    );
  }
}
