import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

void main() {
  runApp(
    MaterialApp(
      home: ResumeScreening(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        cardTheme: CardTheme(
          elevation: 3,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
    ),
  );
}

class ResumeScreening extends StatefulWidget {
  @override
  _ResumeScreeningState createState() => _ResumeScreeningState();
}

class _ResumeScreeningState extends State<ResumeScreening> {
  String? _analysisResult;
  bool _isLoading = false;

  // Helper to parse and display the JSON structure
  Widget _buildAnalysisWidget(String analysis) {
    try {
      final data = jsonDecode(analysis);

      // Extract data from JSON
      final personal = data['personal_info'] ?? {};
      final skills = (data['skills'] as List?)?.cast<String>() ?? [];
      final expSummary = data['experience_summary'] ?? '';
      final score = data['score_breakdown'] ?? {};
      final overall = data['overall_score'];
      final selPred = data['selection_prediction'] ?? {};

      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(overall, selPred),
            SizedBox(height: 16),
            _buildPersonalInfoCard(personal),
            _buildSkillsCard(skills),
            _buildExperienceCard(expSummary),
            _buildScoreBreakdownCard(score),
            _buildImprovementSuggestionsCard(selPred),
          ],
        ),
      );
    } catch (e) {
      // Fallback to plain text display with error handling
      return Center(
        child: Card(
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error Processing Response',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  analysis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildHeaderSection(dynamic overall, Map<String, dynamic> selPred) {
    final probability =
        selPred['probability'] != null
            ? (selPred['probability'] * 100).toStringAsFixed(1)
            : null;
    final isPassing = probability != null && double.parse(probability) >= 70;

    return Card(
      color: isPassing ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPassing ? Icons.check_circle : Icons.info,
                  color: isPassing ? Colors.green : Colors.orange,
                  size: 36,
                ),
                SizedBox(width: 12),
                Text(
                  'Overall Score: ${overall ?? "N/A"}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPassing ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (probability != null)
              Column(
                children: [
                  Text(
                    'Selection Probability: $probability%',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: double.parse(probability) / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPassing ? Colors.green : Colors.orange,
                    ),
                    minHeight: 10,
                  ),
                ],
              ),
            SizedBox(height: 8),
            Text(
              selPred['reason'] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(Map<String, dynamic> personal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            Divider(),
            _buildInfoRow(Icons.badge, 'Name', personal['name'] ?? ''),
            _buildInfoRow(Icons.email, 'Email', personal['email'] ?? ''),
            _buildInfoRow(Icons.phone, 'Phone', personal['phone'] ?? ''),
            _buildInfoRow(Icons.info, 'About', personal['about'] ?? ''),
            _buildInfoRow(Icons.link, 'LinkedIn', personal['linkedin'] ?? ''),
            _buildInfoRow(Icons.code, 'GitHub', personal['github'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value.isEmpty ? 'Not specified' : value,
                  style: TextStyle(
                    fontSize: 15,
                    color: value.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard(List<String> skills) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Skills',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            Divider(),
            skills.isEmpty
                ? Text('No skills listed', style: TextStyle(color: Colors.grey))
                : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      skills
                          .map(
                            (skill) => Chip(
                              backgroundColor: Colors.blue[50],
                              label: Text(skill),
                              labelStyle: TextStyle(color: Colors.blue[700]),
                            ),
                          )
                          .toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceCard(String expSummary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Experience Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            Divider(),
            Text(
              expSummary.isEmpty
                  ? 'No experience summary provided'
                  : expSummary,
              style: TextStyle(
                fontSize: 15,
                color: expSummary.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdownCard(Map<String, dynamic> score) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Score Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            Divider(),
            ...score.entries.map<Widget>((entry) {
              final val = entry.value;
              final scoreVal = val['score'] ?? 0;
              final maxVal = val['max'] ?? 1;
              final percentage = maxVal > 0 ? (scoreVal / maxVal) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${entry.key.replaceAll('_', ' ').toUpperCase()}',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$scoreVal/$maxVal',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(percentage),
                      ),
                      minHeight: 6,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Comments: ${val['comments'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementSuggestionsCard(Map<String, dynamic> selPred) {
    final suggestions = selPred['improvement_suggestions'] as List?;
    if (suggestions == null || suggestions.isEmpty) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Improvement Suggestions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            Divider(),
            ...suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, color: Colors.orange),
                    SizedBox(width: 4),
                    Expanded(child: Text(suggestion.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage < 0.4) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }

  Future<void> _uploadAndAnalyzeFile() async {
    setState(() {
      _isLoading = true;
      _analysisResult = 'Selecting file...';
    });

    // Pick a PDF file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _analysisResult = 'Uploading file...';
      });

      try {
        // Prepare the request with the new endpoint
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://resume-2kvb.onrender.com/'),
        );

        if (kIsWeb) {
          // Web platform handling
          final bytes = result.files.single.bytes;
          final filename = result.files.single.name;
          if (bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes('file', bytes, filename: filename),
            );
          }
        } else {
          // Mobile/Desktop platform handling
          String filePath = result.files.single.path!;
          request.files.add(
            await http.MultipartFile.fromPath('file', filePath),
          );
        }

        request.headers['Accept'] = 'application/json';

        // For debugging
        setState(() {
          _analysisResult = 'Connecting to server...';
        });

        // Send the request with timeout
        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout:
              () =>
                  throw TimeoutException(
                    'Connection timed out after 30 seconds',
                  ),
        );

        setState(() {
          _analysisResult = 'Processing response...';
        });

        var response = await http.Response.fromStream(streamedResponse);

        // Print the raw response body to console
        print('API Response: ${response.body}');

        if (response.statusCode == 200) {
          try {
            var jsonResponse = jsonDecode(response.body);
            // Print the decoded JSON to console
            print('Decoded JSON: $jsonResponse');
            setState(() {
              _isLoading = false;
              // Fix: Convert the JSON object to a string before assigning
              if (jsonResponse['analysis'] is Map) {
                _analysisResult = jsonEncode(jsonResponse['analysis']);
              } else {
                _analysisResult = jsonResponse['analysis'] ?? 'Success, but no analysis data';
              }
            });
          } catch (e) {
            setState(() {
              _isLoading = false;
              _analysisResult =
                  'Error parsing response: $e\nRaw response: ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}';
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _analysisResult =
                'Server error: ${response.statusCode}\nBody: ${response.body}';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _analysisResult =
              'Connection error: $e\n\nVerify that:\n1. Server is running\n2. URL is correct\n3. Internet connection is working';
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _analysisResult = 'File selection canceled.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resume Analysis'),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      _analysisResult ?? 'Processing...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    color: Colors.blue[50],
                    child: Column(
                      children: [
                        Text(
                          'Resume Screening Tool',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload your resume to get comprehensive analysis',
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _uploadAndAnalyzeFile,
                          icon: Icon(Icons.upload_file),
                          label: Text('Upload Resume PDF'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_analysisResult != null)
                    Expanded(child: _buildAnalysisWidget(_analysisResult!)),
                  if (_analysisResult == null)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Upload a resume to see the analysis',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}
