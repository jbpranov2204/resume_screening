import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
      stream: _firestore.collection('resume_analysis_results').snapshots(),
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
              _buildHeader(context, candidates, isMobile),
              SizedBox(height: 24),

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

  Widget _buildHeader(
    BuildContext context,
    List<Map<String, dynamic>> candidates,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 20, 30, 40),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Candidate Analysis Results',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 18 : 22,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Review and contact candidates based on their resume analysis',
            style: GoogleFonts.montserrat(
              color: Colors.grey[400],
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          SizedBox(height: 20),
          isMobile
              ? Column(
                children: [
                  _buildActionButton(
                    'Email All Selected',
                    Icons.email,
                    Colors.green,
                    () => _sendEmailToAllSelected(candidates, context),
                    fullWidth: true,
                  ),
                  SizedBox(height: 8),
                  _buildActionButton(
                    'Download Report',
                    Icons.download,
                    Colors.blue,
                    () {}, // Add download functionality
                    fullWidth: true,
                  ),
                ],
              )
              : Row(
                children: [
                  _buildActionButton(
                    'Email All Selected',
                    Icons.email,
                    Colors.green,
                    () => _sendEmailToAllSelected(candidates, context),
                  ),
                  SizedBox(width: 16),
                  _buildActionButton(
                    'Download Report',
                    Icons.download,
                    Colors.blue,
                    () {}, // Add download functionality
                  ),
                ],
              ),
        ],
      ),
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
                final analysisResult =
                    candidate['analysisResult'] is Map
                        ? Map<String, dynamic>.from(candidate['analysisResult'])
                        : <String, dynamic>{};

                final String name =
                    analysisResult['name']?.toString() ?? 'Unknown';
                final String jobTitle =
                    candidate['jobTitle']?.toString() ?? 'Unknown Position';
                final double score =
                    analysisResult['score'] is num
                        ? analysisResult['score'].toDouble()
                        : 0.0;
                final String email = analysisResult['mail']?.toString() ?? '';

                final Color scoreColor =
                    score > 70
                        ? Colors.green
                        : (score > 50 ? Colors.orange : Colors.red);

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
                                // View candidate details
                              },
                              tooltip: 'View Details',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                // Delete candidate
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

  Widget _buildMobileCandidatesList(
    List<Map<String, dynamic>> candidates,
    BuildContext context,
  ) {
    return ListView.builder(
      itemCount: candidates.length,
      itemBuilder: (context, index) {
        final candidate = candidates[index];
        final analysisResult =
            candidate['analysisResult'] is Map
                ? Map<String, dynamic>.from(candidate['analysisResult'])
                : <String, dynamic>{};

        final String name = analysisResult['name']?.toString() ?? 'Unknown';
        final String jobTitle =
            candidate['jobTitle']?.toString() ?? 'Unknown Position';
        final double score =
            analysisResult['score'] is num
                ? analysisResult['score'].toDouble()
                : 0.0;
        final String email = analysisResult['mail']?.toString() ?? '';

        final Color scoreColor =
            score > 70
                ? Colors.green
                : (score > 50 ? Colors.orange : Colors.red);

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          color: Color.fromARGB(255, 20, 30, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
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
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  jobTitle,
                  style: GoogleFonts.montserrat(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    email,
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMobileActionButton(
                      'View',
                      Icons.visibility,
                      Colors.blue,
                      () {
                        // View candidate details
                      },
                    ),
                    if (email.isNotEmpty)
                      _buildMobileActionButton(
                        'Email',
                        Icons.mail_outline,
                        Colors.green,
                        () => _sendEmail(email, name, context),
                      ),
                    _buildMobileActionButton(
                      'Delete',
                      Icons.delete_outline,
                      Colors.red,
                      () {
                        // Delete candidate
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
