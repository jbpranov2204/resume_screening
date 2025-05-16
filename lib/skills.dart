import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resume_screening/candidates.dart';

class SkillsTab extends StatelessWidget {
  final List<dynamic> skills;

  const SkillsTab({Key? key, required this.skills}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills & Expertise', style: AppTheme.headingStyle),
          SizedBox(height: 16),

          skills.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.engineering,
                      size: 48,
                      color: Colors.grey.shade700,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No skills data available',
                      style: GoogleFonts.montserrat(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    skills.map((skill) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              skill.toString(),
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),

          if (skills.isNotEmpty) ...[
            SizedBox(height: 30),
            Text('Skills Distribution', style: AppTheme.subheadingStyle),
            SizedBox(height: 16),

            Container(
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue,
                      value: 40,
                      title: '40%',
                      radius: 100,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.redAccent,
                      value: 30,
                      title: '30%',
                      radius: 100,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: 15,
                      title: '15%',
                      radius: 100,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.amber,
                      value: 15,
                      title: '15%',
                      radius: 100,
                      titleStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),
            Row(
              children: [
                _buildLegendItem('Technical', Colors.blue),
                _buildLegendItem('Soft Skills', Colors.redAccent),
                _buildLegendItem('Tools', Colors.green),
                _buildLegendItem('Other', Colors.amber),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(width: 16, height: 16, color: color),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
