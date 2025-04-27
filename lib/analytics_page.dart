import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        title: Text(
          'Analytics Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/bg7.jpg', fit: BoxFit.cover),
          ),
          // Semi-transparent overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Title
                Text(
                  'Recruitment Insights',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                // Analytics Cards - Responsive layout
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Use a single column layout for mobile screens
                      if (constraints.maxWidth < 600) {
                        return ListView(
                          children: [
                            _buildAnalyticsCard(
                              title: 'Applications by Source',
                              child: _buildPieChart(),
                              height: 220,
                            ),
                            SizedBox(height: 16),
                            _buildAnalyticsCard(
                              title: 'Jobs by Department',
                              child: _buildBarChart(),
                              height: 220,
                            ),
                            SizedBox(height: 16),
                            _buildAnalyticsCard(
                              title: 'Hiring Trends',
                              child: _buildLineChart(),
                              height: 220,
                            ),
                            SizedBox(height: 16),
                            _buildAnalyticsCard(
                              title: 'Summary',
                              child: _buildSummaryCard(),
                              height: 220,
                            ),
                          ],
                        );
                      } else {
                        // Original grid layout for tablets and desktop
                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: [
                            _buildAnalyticsCard(
                              title: 'Applications by Source',
                              child: _buildPieChart(),
                            ),
                            _buildAnalyticsCard(
                              title: 'Jobs by Department',
                              child: _buildBarChart(),
                            ),
                            _buildAnalyticsCard(
                              title: 'Hiring Trends',
                              child: _buildLineChart(),
                            ),
                            _buildAnalyticsCard(
                              title: 'Summary',
                              child: _buildSummaryCard(),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required Widget child,
    double? height,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: 40,
            color: Colors.blue,
            title: '40%',
            titleStyle: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            radius: 50,
            titlePositionPercentageOffset: 0.55,
          ),
          PieChartSectionData(
            value: 30,
            color: Colors.orange,
            title: '30%',
            titleStyle: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            radius: 50,
            titlePositionPercentageOffset: 0.55,
          ),
          PieChartSectionData(
            value: 20,
            color: Colors.green,
            title: '20%',
            titleStyle: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            radius: 50,
            titlePositionPercentageOffset: 0.55,
          ),
          PieChartSectionData(
            value: 10,
            color: Colors.purple,
            title: '10%',
            titleStyle: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            radius: 50,
            titlePositionPercentageOffset: 0.55,
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'IT';
                    break;
                  case 1:
                    text = 'Sales';
                    break;
                  case 2:
                    text = 'HR';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 25,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 25,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white10, strokeWidth: 1);
          },
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: 8,
                color: Colors.blue,
                width: 15,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: 6,
                color: Colors.orange,
                width: 15,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: 4,
                color: Colors.green,
                width: 15,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white10, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'Q1';
                    break;
                  case 1:
                    text = 'Q2';
                    break;
                  case 2:
                    text = 'Q3';
                    break;
                  case 3:
                    text = 'Q4';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 25,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 3,
        minY: 0,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, 3), FlSpot(1, 5), FlSpot(2, 2), FlSpot(3, 8)],
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: 24,
            color: Colors.blue,
            title: '24',
            titleStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            radius: 50,
            titlePositionPercentageOffset: 0.55,
          ),
          PieChartSectionData(
            value: 347,
            color: Colors.orange,
            title: '347',
            titleStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            radius: 50,
            titlePositionPercentageOffset: 0.55,
          ),
          PieChartSectionData(
            value: 18,
            color: Colors.green,
            title: '18',
            titleStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            radius: 50,
            titlePositionPercentageOffset: 0.55,
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
