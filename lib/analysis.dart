import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the AppTheme from a common file
import 'candidates_details.dart';

class AnalysisTab extends StatelessWidget {
  final String grade;
  final String likelihood;
  final String selectionReason;
  final double probability;
  final List<dynamic> scoreBreakdown;

  const AnalysisTab({
    Key? key,
    required this.grade,
    required this.likelihood,
    required this.selectionReason,
    required this.probability,
    required this.scoreBreakdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detailed Analysis', style: AppTheme.headingStyle),
          SizedBox(height: 16),

          if (grade.isNotEmpty)
            _buildInfoCard('Overall Grade', [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    grade,
                    style: GoogleFonts.montserrat(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                    ),
                  ),
                ),
              ),
            ]),

          SizedBox(height: 20),

          // Detailed score breakdown in a table
          if (scoreBreakdown.isNotEmpty) ...[
            _buildInfoCard('Detailed Scoring', [
              Table(
                border: TableBorder.all(
                  color: Colors.grey.shade800,
                  width: 1,
                  style: BorderStyle.solid,
                ),
                columnWidths: {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                    children: [
                      _buildTableHeader('Category'),
                      _buildTableHeader('Score'),
                      _buildTableHeader('Max'),
                    ],
                  ),
                  ...scoreBreakdown.map((item) {
                    final category = item['category']?.toString() ?? '';
                    final score =
                        item['score'] is num
                            ? (item['score'] as num).toDouble()
                            : 0.0;
                    final max =
                        item['max'] is num
                            ? (item['max'] as num).toDouble()
                            : 100.0;
                    final double percentage =
                        max != 0 ? (score / max * 100) : 0.0;
                    final Color itemColor =
                        percentage > 70
                            ? AppTheme.successColor
                            : (percentage > 50
                                ? AppTheme.warningColor
                                : AppTheme.errorColor);

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            category,
                            style: GoogleFonts.montserrat(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            score.toStringAsFixed(1),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              color: itemColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            max.toStringAsFixed(0),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              SizedBox(height: 16),

              // Show each category with comments if available
              ...scoreBreakdown.map((item) {
                final category = item['category']?.toString() ?? '';
                final comments = item['comments']?.toString() ?? '';

                if (comments.isEmpty) return SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.montserrat(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        comments,
                        style: GoogleFonts.montserrat(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ]),
          ],

          SizedBox(height: 20),

          // Selection prediction
          if (likelihood.isNotEmpty)
            _buildInfoCard('Selection Prediction', [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        probability > 70
                            ? Icons.check_circle
                            : (probability > 50 ? Icons.help : Icons.cancel),
                        color:
                            probability > 70
                                ? AppTheme.successColor
                                : (probability > 50
                                    ? AppTheme.warningColor
                                    : AppTheme.errorColor),
                        size: 30,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          likelihood,
                          style: GoogleFonts.montserrat(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Probability: ${probability}%',
                          style: GoogleFonts.montserrat(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (selectionReason.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Reasoning:',
                  style: GoogleFonts.montserrat(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  selectionReason,
                  style: GoogleFonts.montserrat(color: AppTheme.textPrimary),
                ),
              ],
            ]),
        ],
      ),
    );
  }

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

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
