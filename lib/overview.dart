import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resume_screening/candidates.dart';



class OverviewTab extends StatelessWidget {
  final String name;
  final String jobTitle;
  final String company;
  final String submittedDate;
  final String experienceSummary;
  final String about;
  final double score;
  final String likelihood;
  final int probability;
  final String selectionReason;
  final List<dynamic> scoreBreakdown;
  final List<dynamic> improvementSuggestions;

  const OverviewTab({
    Key? key,
    required this.name,
    required this.jobTitle,
    required this.company,
    required this.submittedDate,
    required this.experienceSummary,
    required this.about,
    required this.score,
    required this.likelihood,
    required this.probability,
    required this.selectionReason,
    required this.scoreBreakdown,
    required this.improvementSuggestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color scoreColor =
        score > 70
            ? AppTheme.successColor
            : (score > 50 ? AppTheme.warningColor : AppTheme.errorColor);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Summary', [
            _buildDetailItem(
              Icons.calendar_today,
              'Submission Date',
              submittedDate,
            ),
            if (experienceSummary.isNotEmpty)
              _buildDetailItem(
                Icons.work_history,
                'Experience Summary',
                experienceSummary,
              ),
            if (about.isNotEmpty)
              _buildDetailItem(Icons.person, 'About', about),
          ]),

          SizedBox(height: 24),

          Text('Score Analysis', style: AppTheme.headingStyle),
          SizedBox(height: 16),
          Container(
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
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: score / 100),
                            duration: Duration(milliseconds: 1500),
                            builder: (context, double value, child) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 10,
                                backgroundColor: Colors.grey.shade800,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  scoreColor,
                                ),
                              );
                            },
                          ),
                          Column(
                            children: [
                              Text(
                                '${score.toInt()}%',
                                style: GoogleFonts.montserrat(
                                  color: scoreColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                score > 70
                                    ? Icons.verified
                                    : (score > 50
                                        ? Icons.thumb_up
                                        : Icons.thumb_down),
                                color: scoreColor,
                              ),
                              SizedBox(width: 8),
                              Text(
                                score > 70
                                    ? 'Excellent Match'
                                    : (score > 50
                                        ? 'Good Potential'
                                        : 'Not Recommended'),
                                style: GoogleFonts.montserrat(
                                  color: scoreColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
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
                          SizedBox(height: 12),
                          if (likelihood.isNotEmpty)
                            Text(
                              'Predicted Outcome: $likelihood ($probability%)',
                              style: GoogleFonts.montserrat(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (selectionReason.isNotEmpty) ...[
                  Divider(color: Colors.grey.shade800, height: 24),
                  Text(
                    'Selection Reasoning:',
                    style: GoogleFonts.montserrat(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    selectionReason,
                    style: GoogleFonts.montserrat(
                      color: AppTheme.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (scoreBreakdown.isNotEmpty) ...[
            SizedBox(height: 24),
            Text('Score Breakdown', style: AppTheme.subheadingStyle),
            SizedBox(height: 10),
            Container(
              height: 250,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: AppTheme.backgroundColor.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String category =
                            scoreBreakdown[group.x.toInt()]['category']
                                ?.toString() ??
                            '';
                        double score =
                            scoreBreakdown[group.x.toInt()]['score'] is num
                                ? (scoreBreakdown[group.x.toInt()]['score']
                                        as num)
                                    .toDouble()
                                : 0.0;
                        double max =
                            scoreBreakdown[group.x.toInt()]['max'] is num
                                ? (scoreBreakdown[group.x.toInt()]['max']
                                        as num)
                                    .toDouble()
                                : 100.0;
                        return BarTooltipItem(
                          '$category\n${score.toInt()}/${max.toInt()}',
                          GoogleFonts.montserrat(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
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
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 20,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine:
                        (value) => FlLine(
                          color: Colors.grey.shade800,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                  ),
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
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],

          if (improvementSuggestions.isNotEmpty) ...[
            SizedBox(height: 24),
            _buildInfoCard('Improvement Suggestions', [
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
            ]),
          ],

          SizedBox(height: 24),
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
}
