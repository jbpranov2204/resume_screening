import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this dependency for charts
import 'candidates_details.dart'; // Import the new details page

// Define a professional theme class for consistent styling
class AppTheme {
  static const Color primaryColor = Color(0xFF3498DB);
  static const Color secondaryColor = Color(0xFFFFD700);
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

class CandidatesPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _sendEmail(
    String email,
    String name,
    BuildContext context,
  ) async {
    try {
      // Store email data in sent_mails collection
      await _firestore.collection('sent_mails').add({
        'sender': 'yuvkri2004@gmail.com',
        'recipients': [email],
        'subject': 'Congratulations on Your Selection',
        'body':
            'Dear $name,\n\n'
            'Congratulations on being selected! We are excited to have you on board. '
            'Please feel free to reach out to us for any queries.\n\n'
            'Best regards,\n[Your Company Name]\n[Company Contact Link]',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email to $name will be sent from yuvkri2004@gmail.com',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending email: $e')));
    }
  }

  Future<void> _sendEmailToAllSelected(
    List<Map<String, dynamic>> candidates,
    BuildContext context,
  ) async {
    final selectedCandidates =
        candidates.where((candidate) {
          final analysisResult =
              candidate['analysisResult'] is Map
                  ? Map<String, dynamic>.from(candidate['analysisResult'])
                  : <String, dynamic>{};
          final double score =
              analysisResult['score'] is num
                  ? analysisResult['score'].toDouble()
                  : 0.0;
          return score > 50;
        }).toList();

    if (selectedCandidates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No selected candidates found')));
      return;
    }

    // Collect all recipient emails and names
    final List<String> emails = [];
    final List<String> names = [];

    for (var candidate in selectedCandidates) {
      final analysisResult =
          candidate['analysisResult'] is Map
              ? Map<String, dynamic>.from(candidate['analysisResult'])
              : <String, dynamic>{};
      final String email = analysisResult['mail']?.toString() ?? '';
      final String name = analysisResult['name']?.toString() ?? 'Candidate';

      if (email.isNotEmpty) {
        emails.add(email);
        names.add(name);
      }
    }

    if (emails.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No valid emails found')));
      return;
    }

    try {
      // Store bulk email data in sent_mails collection
      await _firestore.collection('sent_mails').add({
        'sender': 'yuvkri2004@gmail.com',
        'recipients': emails,
        'recipientNames': names,
        'subject': 'Congratulations on Your Selection',
        'body':
            'Dear Selected Candidates,\n\n'
            'Congratulations on being selected! We are excited to have you on board. '
            'Best regards,\n[Your Company Name]\n[Company Contact Link]',
        'isBulkEmail': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Emails will be sent to ${emails.length} selected candidates from yuvkri2004@gmail.com',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending emails: ${e.toString()}')),
      );
    }
  }

  void _deleteCandidate(String candidateId, BuildContext context) async {
    try {
      await _firestore.collection('resume_analysis').doc(candidateId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Candidate deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting candidate: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on mobile or web based on screen width
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 9, 16, 22),
        title: Row(
          children: [
            Icon(Icons.people_outline, color: Color(0xFFFFD700)),
            SizedBox(width: 12),
            Text(
              'Candidates',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isMobile ? 20 : 24,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildCandidatesView(context, isMobile),
    );
  }

  Widget _buildCandidatesView(BuildContext context, bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('resume_analysis').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading candidates: ${snapshot.error}',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, color: Colors.grey, size: 64),
                SizedBox(height: 16),
                Text(
                  'No candidates found',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          );
        }

        // Convert documents to map
        final List<Map<String, dynamic>> candidates =
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {'id': doc.id, ...data};
            }).toList();

        // Sort by score from highest to lowest
        candidates.sort((a, b) {
          final aResult =
              a['analysisResult'] is Map
                  ? Map<String, dynamic>.from(a['analysisResult'])
                  : <String, dynamic>{};
          final bResult =
              b['analysisResult'] is Map
                  ? Map<String, dynamic>.from(b['analysisResult'])
                  : <String, dynamic>{};

          final double aScore =
              aResult['score'] is num ? aResult['score'].toDouble() : 0.0;
          final double bScore =
              bResult['score'] is num ? bResult['score'].toDouble() : 0.0;

          return bScore.compareTo(aScore);
        });

        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with action buttons

              // Candidates list
              Expanded(
                child:
                    isMobile
                        ? _buildMobileCandidatesList(candidates, context)
                        : _buildWebCandidatesList(candidates, context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // New method to build score visualization
  Widget _buildScoreVisualization(double score, List<dynamic> scoreBreakdown) {
    final Color scoreColor =
        score > 70
            ? AppTheme.successColor
            : (score > 50 ? AppTheme.warningColor : AppTheme.errorColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall score gauge
        Container(
          height: 120,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Circular progress indicator for score
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${score.toInt()}%',
                          style: GoogleFonts.montserrat(
                            color: scoreColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Score',
                          style: GoogleFonts.montserrat(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),
              // Score interpretation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score > 70
                          ? 'Excellent Match'
                          : (score > 50 ? 'Good Potential' : 'Not Recommended'),
                      style: GoogleFonts.montserrat(
                        color: scoreColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      score > 70
                          ? 'This candidate is highly suitable for the position.'
                          : (score > 50
                              ? 'This candidate shows potential but may need development.'
                              : 'This candidate is not recommended for this position.'),
                      style: GoogleFonts.montserrat(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Score breakdown chart (if available)
        if (scoreBreakdown.isNotEmpty) ...[
          SizedBox(height: 20),
          Text('Score Breakdown', style: AppTheme.subheadingStyle),
          SizedBox(height: 10),
          Container(
            height: 200,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        // Get short category names
                        String text = '';
                        if (value < scoreBreakdown.length) {
                          String category =
                              scoreBreakdown[value.toInt()]['category']
                                  ?.toString() ??
                              '';
                          text =
                              category.length > 5
                                  ? category.substring(0, 5)
                                  : category;
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            text,
                            style: GoogleFonts.montserrat(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.montserrat(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  scoreBreakdown.length > 5 ? 5 : scoreBreakdown.length,
                  (index) {
                    final item = scoreBreakdown[index];
                    final score =
                        item['score'] is num
                            ? (item['score'] as num).toDouble()
                            : 0.0;
                    final max =
                        item['max'] is num
                            ? (item['max'] as num).toDouble()
                            : 100.0;

                    // Convert to percentage if max is not 100
                    final percentage = max != 0 ? (score / max * 100) : 0.0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: percentage,
                          color:
                              percentage > 70
                                  ? AppTheme.successColor
                                  : (percentage > 50
                                      ? AppTheme.warningColor
                                      : AppTheme.errorColor),
                          borderRadius: BorderRadius.circular(4),
                          width: 20,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Helper method to build an info card for candidate details
  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Divider(color: Colors.grey.shade800, height: 24),
          ...children,
        ],
      ),
    );
  }

  // Helper method to build detail items with icons
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.secondaryColor, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.montserrat(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Replace the old detail page with improved UI
  Widget _buildCandidateDetailView(
    BuildContext context,
    String name,
    String email,
    String phone,
    String about,
    String github,
    String linkedin,
    String jobTitle,
    String company,
    String submittedDate,
    String experienceSummary,
    String grade,
    List<dynamic> improvementSuggestions,
    List<dynamic> skills,
    List<dynamic> scoreBreakdown,
    double score,
    String likelihood,
    int probability,
    String selectionReason,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with candidate name and actions
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 24,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.montserrat(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            jobTitle,
                            style: GoogleFonts.montserrat(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (email.isNotEmpty)
                      _buildContactButton(
                        'Email',
                        Icons.email,
                        () => _sendEmail(email, name, context),
                      ),
                    if (phone.isNotEmpty)
                      _buildContactButton(
                        'Call',
                        Icons.phone,
                        () => launchUrl(Uri.parse('tel:$phone')),
                      ),
                    if (linkedin.isNotEmpty)
                      _buildContactButton(
                        'LinkedIn',
                        Icons.work,
                        () => launchUrl(Uri.parse(linkedin)),
                      ),
                    if (github.isNotEmpty)
                      _buildContactButton(
                        'GitHub',
                        Icons.code,
                        () => launchUrl(Uri.parse(github)),
                      ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Score visualization section
          _buildScoreVisualization(score, scoreBreakdown),

          SizedBox(height: 24),

          // Personal Information
          _buildInfoCard('Personal Information', [
            if (email.isNotEmpty) _buildDetailItem(Icons.email, 'Email', email),
            if (phone.isNotEmpty) _buildDetailItem(Icons.phone, 'Phone', phone),
            if (about.isNotEmpty)
              _buildDetailItem(Icons.person, 'About', about),
            _buildDetailItem(Icons.business, 'Company', company),
            _buildDetailItem(Icons.calendar_today, 'Submitted', submittedDate),
          ]),

          // Experience
          if (experienceSummary.isNotEmpty)
            _buildInfoCard('Experience', [
              _buildDetailItem(
                Icons.work_history,
                'Summary',
                experienceSummary,
              ),
            ]),

          // Skills
          if (skills.isNotEmpty)
            _buildInfoCard('Skills', [
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
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
              ),
            ]),

          // Assessment
          if (grade.isNotEmpty || improvementSuggestions.isNotEmpty)
            _buildInfoCard('Assessment', [
              if (grade.isNotEmpty)
                _buildDetailItem(Icons.grade, 'Grade', grade),
              if (improvementSuggestions.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Improvement Suggestions',
                  style: GoogleFonts.montserrat(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                ...improvementSuggestions.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_right,
                          color: AppTheme.warningColor,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion.toString(),
                            style: GoogleFonts.montserrat(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ]),

          // Selection Prediction
          if (likelihood.isNotEmpty)
            _buildInfoCard('Selection Prediction', [
              _buildDetailItem(
                Icons.analytics,
                'Likelihood',
                '$likelihood ($probability%)',
              ),
              if (selectionReason.isNotEmpty)
                _buildDetailItem(Icons.info_outline, 'Reason', selectionReason),
            ]),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper for contact buttons
  Widget _buildContactButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 18),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Replace the _buildMobileCandidatesList method to navigate to the details page instead of showing bottom sheet
  Widget _buildMobileCandidatesList(
    List<Map<String, dynamic>> candidates,
    BuildContext context,
  ) {
    return ListView.builder(
      itemCount: candidates.length,
      itemBuilder: (context, index) {
        final candidate = candidates[index];
        final analysis =
            candidate['analysis'] is Map
                ? Map<String, dynamic>.from(candidate['analysis'])
                : <String, dynamic>{};

        // Extract all fields from Firestore data
        final personalInfo =
            analysis['personal_info'] is Map
                ? Map<String, dynamic>.from(analysis['personal_info'])
                : <String, dynamic>{};
        final String name =
            personalInfo['name']?.toString() ??
            analysis['name']?.toString() ??
            'Unknown';
        final String email =
            personalInfo['email']?.toString() ??
            analysis['mail']?.toString() ??
            '';
        final String phone = personalInfo['phone']?.toString() ?? '';
        final String about = personalInfo['about']?.toString() ?? '';
        final String github = personalInfo['github']?.toString() ?? '';
        final String linkedin = personalInfo['linkedin']?.toString() ?? '';

        final String experienceSummary =
            analysis['experience_summary']?.toString() ?? '';
        final String grade = analysis['grade']?.toString() ?? '';
        final List<dynamic> improvementSuggestions =
            analysis['improvement_suggestions'] is List
                ? List<dynamic>.from(analysis['improvement_suggestions'])
                : <dynamic>[];
        final double score =
            analysis['overall_score'] is num
                ? (analysis['overall_score'] as num).toDouble()
                : analysis['score'] is num
                ? (analysis['score'] as num).toDouble()
                : 0.0;
        final List<dynamic> scoreBreakdown =
            analysis['score_breakdown'] is List
                ? List<dynamic>.from(analysis['score_breakdown'])
                : <dynamic>[];
        final selectionPrediction =
            analysis['selection_prediction'] is Map
                ? Map<String, dynamic>.from(analysis['selection_prediction'])
                : <String, dynamic>{};
        final String likelihood =
            selectionPrediction['likelihood']?.toString() ?? '';
        final int probability =
            selectionPrediction['probability'] is num
                ? (selectionPrediction['probability'] as num).toInt()
                : 0;
        final String selectionReason =
            selectionPrediction['reason']?.toString() ?? '';
        final List<dynamic> skills =
            analysis['skills'] is List
                ? List<dynamic>.from(analysis['skills'])
                : <dynamic>[];

        // Job and document details
        final String jobTitle =
            candidate['jobTitle']?.toString() ?? 'Unknown Position';
        final String company =
            candidate['company']?.toString() ?? 'Unknown Company';

        // Format timestamp if available
        String submittedDate = 'Unknown date';
        if (candidate['timestamp'] != null) {
          try {
            final timestamp = candidate['timestamp'] as Timestamp;
            final dateTime = timestamp.toDate();
            submittedDate =
                '${dateTime.day}/${dateTime.month}/${dateTime.year}';
          } catch (e) {
            print('Error formatting timestamp: $e');
          }
        }

        final Color scoreColor =
            score > 70
                ? AppTheme.successColor
                : (score > 50 ? AppTheme.warningColor : AppTheme.errorColor);

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          color: AppTheme.cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () {
              // Navigate to detailed page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => CandidateDetailsTabBar(
                        name: name,
                        email: email,
                        phone: phone,
                        about: about,
                        github: github,
                        linkedin: linkedin,
                        jobTitle: jobTitle,
                        company: company,
                        submittedDate: submittedDate,
                        experienceSummary: experienceSummary,
                        grade: grade,
                        improvementSuggestions: improvementSuggestions,
                        skills: skills,
                        scoreBreakdown: scoreBreakdown,
                        score: score,
                        likelihood: likelihood,
                        probability: probability,
                        selectionReason: selectionReason,
                        sendEmail: _sendEmail,
                      ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.montserrat(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
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
                              name,
                              style: GoogleFonts.montserrat(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              jobTitle,
                              style: GoogleFonts.montserrat(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Simple animated circular progress indicator
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: score / 100),
                        duration: Duration(milliseconds: 1000),
                        builder: (context, double value, child) {
                          return Container(
                            width: 100, // Increased from 50
                            height: 100, // Increased from 50
                            child: Stack(
                              alignment:
                                  Alignment.center, // Ensure center alignment
                              children: [
                                CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 8, // Increased from 6
                                  backgroundColor: Colors.grey.shade800,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    scoreColor,
                                  ),
                                ),
                                // Better positioned percentage text
                                Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${score.toInt()}%',
                                    style: GoogleFonts.montserrat(
                                      color: scoreColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12, // Increased from 12
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Company and submission info
                  Row(
                    children: [
                      Expanded(child: _buildInfoTag(Icons.business, company)),
                      Expanded(
                        child: _buildInfoTag(
                          Icons.calendar_today,
                          submittedDate,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Contact info
                  if (email.isNotEmpty || phone.isNotEmpty)
                    Row(
                      children: [
                        if (email.isNotEmpty)
                          Expanded(child: _buildInfoTag(Icons.email, email)),
                        if (phone.isNotEmpty)
                          Expanded(child: _buildInfoTag(Icons.phone, phone)),
                      ],
                    ),

                  // Skills preview (limited to 3)
                  if (skills.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          skills
                              .take(3)
                              .map(
                                (skill) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    skill.toString(),
                                    style: GoogleFonts.montserrat(
                                      color: AppTheme.primaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    if (skills.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '+ ${skills.length - 3} more skills',
                          style: GoogleFonts.montserrat(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],

                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Tap to see details',
                        style: GoogleFonts.montserrat(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Small info tag helper
  Widget _buildInfoTag(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Also update the web view for consistency
  Widget _buildWebCandidatesList(
    List<Map<String, dynamic>> candidates,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 20, 30, 40),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Candidate',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Job Position',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Company',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Score',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Contact',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Actions',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[800], height: 1),

          // Table content
          Expanded(
            child: ListView.separated(
              itemCount: candidates.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(color: Colors.grey[800], height: 1),
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                final analysis =
                    candidate['analysis'] is Map
                        ? Map<String, dynamic>.from(candidate['analysis'])
                        : <String, dynamic>{};

                // Extract all fields from Firestore data
                final personalInfo =
                    analysis['personal_info'] is Map
                        ? Map<String, dynamic>.from(analysis['personal_info'])
                        : <String, dynamic>{};
                final String name =
                    personalInfo['name']?.toString() ??
                    analysis['name']?.toString() ??
                    'Unknown';
                final String email =
                    personalInfo['email']?.toString() ??
                    analysis['mail']?.toString() ??
                    '';
                final String phone = personalInfo['phone']?.toString() ?? '';
                final String about = personalInfo['about']?.toString() ?? '';
                final String github = personalInfo['github']?.toString() ?? '';
                final String linkedin =
                    personalInfo['linkedin']?.toString() ?? '';

                final String experienceSummary =
                    analysis['experience_summary']?.toString() ?? '';
                final String grade = analysis['grade']?.toString() ?? '';
                final List<dynamic> improvementSuggestions =
                    analysis['improvement_suggestions'] is List
                        ? List<dynamic>.from(
                          analysis['improvement_suggestions'],
                        )
                        : <dynamic>[];
                final double score =
                    analysis['overall_score'] is num
                        ? (analysis['overall_score'] as num).toDouble()
                        : analysis['score'] is num
                        ? (analysis['score'] as num).toDouble()
                        : 0.0;
                final List<dynamic> scoreBreakdown =
                    analysis['score_breakdown'] is List
                        ? List<dynamic>.from(analysis['score_breakdown'])
                        : <dynamic>[];
                final selectionPrediction =
                    analysis['selection_prediction'] is Map
                        ? Map<String, dynamic>.from(
                          analysis['selection_prediction'],
                        )
                        : <String, dynamic>{};
                final String likelihood =
                    selectionPrediction['likelihood']?.toString() ?? '';
                final int probability =
                    selectionPrediction['probability'] is num
                        ? (selectionPrediction['probability'] as num).toInt()
                        : 0;
                final String selectionReason =
                    selectionPrediction['reason']?.toString() ?? '';
                final List<dynamic> skills =
                    analysis['skills'] is List
                        ? List<dynamic>.from(analysis['skills'])
                        : <dynamic>[];

                // Job and document details
                final String jobTitle =
                    candidate['jobTitle']?.toString() ?? 'Unknown Position';
                final String company =
                    candidate['company']?.toString() ?? 'Unknown Company';

                // Format timestamp if available
                String submittedDate = 'Unknown date';
                if (candidate['timestamp'] != null) {
                  try {
                    final timestamp = candidate['timestamp'] as Timestamp;
                    final dateTime = timestamp.toDate();
                    submittedDate =
                        '${dateTime.day}/${dateTime.month}/${dateTime.year}';
                  } catch (e) {
                    print('Error formatting timestamp: $e');
                  }
                }

                final Color scoreColor =
                    score > 70
                        ? AppTheme.successColor
                        : (score > 50
                            ? AppTheme.warningColor
                            : AppTheme.errorColor);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      // Candidate name and email
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: GoogleFonts.montserrat(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            if (phone.isNotEmpty)
                              Text(
                                phone,
                                style: GoogleFonts.montserrat(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            SizedBox(height: 4),

                            Text(
                              'Submitted: $submittedDate',
                              style: GoogleFonts.montserrat(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Job position
                      Expanded(
                        flex: 2,
                        child: Text(
                          jobTitle,
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                      ),
                      // Company
                      Expanded(
                        flex: 2,
                        child: Text(
                          company,
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                      ),
                      // Score
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${score.toStringAsFixed(0)}%',
                              style: GoogleFonts.montserrat(
                                color: scoreColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Contact info
                      Expanded(
                        flex: 2,
                        child: Center(
                          child:
                              email.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.mail_outline,
                                      color: Colors.blue,
                                    ),
                                    onPressed:
                                        () => _sendEmail(email, name, context),
                                    tooltip: 'Send Email',
                                  )
                                  : Text(
                                    'No email',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                        ),
                      ),
                      // Actions
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility, color: Colors.green),
                              onPressed: () {
                                // Replace dialog with navigation to the details page
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => CandidateDetailsTabBar(
                                          name: name,
                                          email: email,
                                          phone: phone,
                                          about: about,
                                          github: github,
                                          linkedin: linkedin,
                                          jobTitle: jobTitle,
                                          company: company,
                                          submittedDate: submittedDate,
                                          experienceSummary: experienceSummary,
                                          grade: grade,
                                          improvementSuggestions:
                                              improvementSuggestions,
                                          skills: skills,
                                          scoreBreakdown: scoreBreakdown,
                                          score: score,
                                          likelihood: likelihood,
                                          probability: probability,
                                          selectionReason: selectionReason,
                                          sendEmail: _sendEmail,
                                        ),
                                  ),
                                );
                              },
                              tooltip: 'View Details',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Delete Candidate'),
                                      content: Text(
                                        'Are you sure you want to delete this candidate?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _deleteCandidate(
                                              candidate['id'],
                                              context,
                                            );
                                          },
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        label,
        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size(80, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
