import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CandidatesPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _sendEmail(String email, String name, BuildContext context) async {
    try {
      // Store email data in sent_mails collection
      await _firestore.collection('sent_mails').add({
        'sender': 'yuvkri2004@gmail.com',
        'recipients': [email],
        'subject': 'Congratulations on Your Selection',
        'body': 'Dear $name,\n\n'
            'Congratulations on being selected! We are excited to have you on board. '
            'Please feel free to reach out to us for any queries.\n\n'
            'Best regards,\n[Your Company Name]\n[Company Contact Link]',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email to $name will be sent from yuvkri2004@gmail.com')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email: $e')),
      );
    }
  }

  Future<void> _sendEmailToAllSelected(List<Map<String, dynamic>> candidates, BuildContext context) async {
    final selectedCandidates = candidates.where((candidate) {
      final analysisResult = candidate['analysisResult'] is Map 
          ? Map<String, dynamic>.from(candidate['analysisResult']) 
          : <String, dynamic>{};
      final double score = analysisResult['score'] is num 
          ? analysisResult['score'].toDouble() 
          : 0.0;
      return score > 50;
    }).toList();
    
    if (selectedCandidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No selected candidates found')),
      );
      return;
    }
    
    // Collect all recipient emails and names
    final List<String> emails = [];
    final List<String> names = [];
    
    for (var candidate in selectedCandidates) {
      final analysisResult = candidate['analysisResult'] is Map 
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No valid emails found')),
      );
      return;
    }
    
    try {
      // Store bulk email data in sent_mails collection
      await _firestore.collection('sent_mails').add({
        'sender': 'yuvkri2004@gmail.com',
        'recipients': emails,
        'recipientNames': names,
        'subject': 'Congratulations on Your Selection',
        'body': 'Dear Selected Candidates,\n\n'
            'Congratulations on being selected! We are excited to have you on board. '
            'Please feel free to reach out to us for any queries.\n\n'
            'Best regards,\n[Your Company Name]\n[Company Contact Link]',
        'isBulkEmail': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emails will be sent to ${emails.length} selected candidates from yuvkri2004@gmail.com')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending emails: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Applied Candidates',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('resume_analysis_results').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SizedBox.shrink();
              }
              
              List<Map<String, dynamic>> candidates = snapshot.data!.docs.map((doc) {
                var docData = doc.data();
                return docData is Map ? Map<String, dynamic>.from(docData) : <String, dynamic>{};
              }).toList();
              
              return IconButton(
                icon: Icon(Icons.email, color: Colors.white),
                tooltip: 'Email All Selected',
                onPressed: () => _sendEmailToAllSelected(candidates, context),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('resume_analysis_results').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error fetching candidates',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No candidates found',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var docData = snapshot.data!.docs[index].data();
                Map<String, dynamic> candidate = docData is Map ? Map<String, dynamic>.from(docData) : {};

                // Safely extract nested data
                final analysisResult = candidate['analysisResult'] is Map 
                    ? Map<String, dynamic>.from(candidate['analysisResult']) 
                    : <String, dynamic>{};

                final String name = analysisResult['name']?.toString() ?? 'Unknown';
                final String email = analysisResult['mail']?.toString() ?? 'jbpranov@gmail.com';
                final String experience = analysisResult['experience']?.toString() ?? 'No Experience';
                final dynamic skillsData = analysisResult['skills'];
                final String skills = skillsData is List 
                    ? skillsData.map((e) => e?.toString()).join(', ') 
                    : skillsData?.toString() ?? 'N/A';
                final double score = analysisResult['score'] is num 
                    ? analysisResult['score'].toDouble() 
                    : 0.0;
                final String status = score > 50
                    ? 'Selected'
                    : (score == 50 ? 'Pending' : 'Not Selected');
                final bool isShortlisted = status == 'Selected';

                return Card(
                  color: Colors.grey.shade900,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isShortlisted
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isShortlisted ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _sendEmail(email, name, context),
                          child: Text(
                            'Email: $email',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          'Experience: $experience',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Skills: $skills',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Score: ${score.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}