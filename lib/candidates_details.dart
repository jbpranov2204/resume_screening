import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final Color scoreColor =
        widget.score > 70
            ? AppTheme.successColor
            : (widget.score > 50 ? AppTheme.warningColor : AppTheme.errorColor);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.cardColor,
              flexibleSpace: FlexibleSpaceBar(
                title:
                    _isAppBarExpanded
                        ? null // Avoid showing the name while scrolling
                        : null,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.8),
                            AppTheme.cardColor,
                          ],
                        ),
                      ),
                    ),
                    // Candidate info - moved up with center alignment
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 30,
                                child: Text(
                                  widget.name.isNotEmpty
                                      ? widget.name[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.montserrat(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                    Text(
                                      widget.jobTitle,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      widget.company,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildScoreBadge(scoreColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.share, color: Colors.white),
                  onPressed: () async {
                    final String message =
                        'Candidate Details:\n'
                        'Name: ${widget.name}\n'
                        'Job Title: ${widget.jobTitle}\n'
                        'Company: ${widget.company}\n'
                        'Score: ${widget.score.toInt()}%\n'
                        'Email: ${widget.email}\n'
                        'Phone: ${widget.phone}\n'
                        'About: ${widget.about}\n'
                        'GitHub: ${widget.github}\n'
                        'LinkedIn: ${widget.linkedin}\n';

                    final Uri whatsappUri = Uri.parse(
                      'https://wa.me/?text=${Uri.encodeComponent(message)}',
                    );

                    final Uri telegramUri = Uri.parse(
                      'https://t.me/share/url?url=${Uri.encodeComponent(message)}',
                    );

                    final Uri linkedinUri = Uri.parse(
                      'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(message)}',
                    );

                    final Uri instagramUri = Uri.parse(
                      'https://www.instagram.com/?url=${Uri.encodeComponent(message)}',
                    );

                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: AppTheme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.share,
                                      color: AppTheme.primaryColor,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Candidate Details',
                                      style: AppTheme.headingStyle,
                                    ),
                                  ],
                                ),
                                Divider(
                                  color: Colors.grey.shade800,
                                  height: 24,
                                ),
                                Text(
                                  'Choose a platform to share:',
                                  style: AppTheme.bodyStyle,
                                ),
                                SizedBox(height: 20),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _buildShareOption(
                                      context,
                                      'WhatsApp',
                                      Icons.chat,
                                      Color(0xFF25D366),
                                      () async {
                                        Navigator.of(context).pop();
                                        if (await canLaunchUrl(whatsappUri)) {
                                          await launchUrl(
                                            whatsappUri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Could not open WhatsApp.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    _buildShareOption(
                                      context,
                                      'Telegram',
                                      Icons.send,
                                      Color(0xFF0088cc),
                                      () async {
                                        Navigator.of(context).pop();
                                        if (await canLaunchUrl(telegramUri)) {
                                          await launchUrl(
                                            telegramUri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Could not open Telegram.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    _buildShareOption(
                                      context,
                                      'LinkedIn',
                                      Icons.business_center,
                                      Color(0xFF0077B5),
                                      () async {
                                        Navigator.of(context).pop();
                                        if (await canLaunchUrl(linkedinUri)) {
                                          await launchUrl(
                                            linkedinUri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Could not open LinkedIn.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    _buildShareOption(
                                      context,
                                      'Instagram',
                                      Icons.camera_alt,
                                      Color(0xFFE1306C),
                                      () async {
                                        Navigator.of(context).pop();
                                        if (await canLaunchUrl(instagramUri)) {
                                          await launchUrl(
                                            instagramUri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Could not open Instagram.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  tooltip: 'Share',
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
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildSkillsTab(),
            _buildAnalysisTab(),
            _buildContactTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(Color scoreColor) {
    return Hero(
      tag: 'score-${widget.name}',
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(color: scoreColor, width: 3),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.score.toInt()}%',
                style: GoogleFonts.montserrat(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Score',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final Color scoreColor =
        widget.score > 70
            ? AppTheme.successColor
            : (widget.score > 50 ? AppTheme.warningColor : AppTheme.errorColor);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          _buildInfoCard('Summary', [
            _buildDetailItem(
              Icons.calendar_today,
              'Submission Date',
              widget.submittedDate,
            ),
            if (widget.experienceSummary.isNotEmpty)
              _buildDetailItem(
                Icons.work_history,
                'Experience Summary',
                widget.experienceSummary,
              ),
            if (widget.about.isNotEmpty)
              _buildDetailItem(Icons.person, 'About', widget.about),
          ]),

          SizedBox(height: 24),

          // Score visualization
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
                    // Circular progress indicator for score
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder(
                            tween: Tween<double>(
                              begin: 0,
                              end: widget.score / 100,
                            ),
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
                                '${widget.score.toInt()}%',
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
                    // Score interpretation
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.score > 70
                                    ? Icons.verified
                                    : (widget.score > 50
                                        ? Icons.thumb_up
                                        : Icons.thumb_down),
                                color: scoreColor,
                              ),
                              SizedBox(width: 8),
                              Text(
                                widget.score > 70
                                    ? 'Excellent Match'
                                    : (widget.score > 50
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
                            widget.score > 70
                                ? 'This candidate is highly suitable for the position.'
                                : (widget.score > 50
                                    ? 'This candidate shows potential but may need development.'
                                    : 'This candidate is not recommended for this position.'),
                            style: GoogleFonts.montserrat(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 12),
                          if (widget.likelihood.isNotEmpty)
                            Text(
                              'Predicted Outcome: ${widget.likelihood} (${widget.probability}%)',
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

                if (widget.selectionReason.isNotEmpty) ...[
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
                    widget.selectionReason,
                    style: GoogleFonts.montserrat(
                      color: AppTheme.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Score breakdown chart
          if (widget.scoreBreakdown.isNotEmpty) ...[
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
                            widget.scoreBreakdown[group.x.toInt()]['category']
                                ?.toString() ??
                            '';
                        double score =
                            widget.scoreBreakdown[group.x.toInt()]['score']
                                    is num
                                ? (widget.scoreBreakdown[group.x
                                            .toInt()]['score']
                                        as num)
                                    .toDouble()
                                : 0.0;
                        double max =
                            widget.scoreBreakdown[group.x.toInt()]['max'] is num
                                ? (widget.scoreBreakdown[group.x.toInt()]['max']
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
                          // Get short category names
                          String text = '';
                          if (value < widget.scoreBreakdown.length) {
                            String category =
                                widget.scoreBreakdown[value.toInt()]['category']
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
                    widget.scoreBreakdown.length > 5
                        ? 5
                        : widget.scoreBreakdown.length,
                    (index) {
                      final item = widget.scoreBreakdown[index];
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

          if (widget.improvementSuggestions.isNotEmpty) ...[
            SizedBox(height: 24),
            _buildInfoCard('Improvement Suggestions', [
              ...widget.improvementSuggestions.map(
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

  Widget _buildSkillsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills & Expertise', style: AppTheme.headingStyle),
          SizedBox(height: 16),

          // Show skills as interactive chips
          widget.skills.isEmpty
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
                    widget.skills.map((skill) {
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

          if (widget.skills.isNotEmpty) ...[
            SizedBox(height: 30),
            Text('Skills Distribution', style: AppTheme.subheadingStyle),
            SizedBox(height: 16),

            // Simple skills visualization - categorize as technical, soft, etc.
            // This is a placeholder - in a real app, you would use the actual data
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

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detailed Analysis', style: AppTheme.headingStyle),
          SizedBox(height: 16),

          if (widget.grade.isNotEmpty)
            _buildInfoCard('Overall Grade', [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.grade,
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
          if (widget.scoreBreakdown.isNotEmpty) ...[
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
                  ...widget.scoreBreakdown.map((item) {
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
              ...widget.scoreBreakdown.map((item) {
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
          if (widget.likelihood.isNotEmpty)
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
                        widget.probability > 70
                            ? Icons.check_circle
                            : (widget.probability > 50
                                ? Icons.help
                                : Icons.cancel),
                        color:
                            widget.probability > 70
                                ? AppTheme.successColor
                                : (widget.probability > 50
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
                          widget.likelihood,
                          style: GoogleFonts.montserrat(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Probability: ${widget.probability}%',
                          style: GoogleFonts.montserrat(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.selectionReason.isNotEmpty) ...[
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
                  widget.selectionReason,
                  style: GoogleFonts.montserrat(color: AppTheme.textPrimary),
                ),
              ],
            ]),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Information', style: AppTheme.headingStyle),
          SizedBox(height: 16),

          // Personal Contact card
          _buildInfoCard('Personal Contact', [
            if (widget.email.isNotEmpty)
              _buildContactItem(
                'Email',
                widget.email,
                Icons.email,
                AppTheme.primaryColor,
                () => launchUrl(Uri.parse('mailto:${widget.email}')),
              ),
            if (widget.phone.isNotEmpty)
              _buildContactItem(
                'Phone',
                widget.phone,
                Icons.phone,
                Colors.green,
                () => launchUrl(Uri.parse('tel:${widget.phone}')),
              ),
            if (widget.linkedin.isNotEmpty)
              _buildContactItem(
                'LinkedIn',
                widget.linkedin,
                Icons.work,
                Colors.blue,
                () => launchUrl(Uri.parse(_normalizeUrl(widget.linkedin))),
              ),
            if (widget.github.isNotEmpty)
              _buildContactItem(
                'GitHub',
                widget.github,
                Icons.code,
                Colors.purple,
                () => launchUrl(Uri.parse(_normalizeUrl(widget.github))),
              ),
            if (widget.email.isEmpty &&
                widget.phone.isEmpty &&
                widget.linkedin.isEmpty &&
                widget.github.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.contact_phone,
                      size: 48,
                      color: Colors.grey.shade700,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No contact information available',
                      style: GoogleFonts.montserrat(color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ]),

          SizedBox(height: 20),

          // Communication card - separate from the Personal Contact card
          if (widget.email.isNotEmpty && widget.sendEmail != null)
            // Company information card - separate from the other cards
            _buildInfoCard('Company Information', [
              _buildDetailItem(Icons.business, 'Company', widget.company),
              _buildDetailItem(Icons.work, 'Position', widget.jobTitle),
              _buildDetailItem(
                Icons.calendar_today,
                'Application Date',
                widget.submittedDate,
              ),
            ]),
        ],
      ),
    );
  }

  // Helper to ensure URLs are valid for LinkedIn and GitHub
  String _normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }

  Widget _buildContactItem(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.montserrat(color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: AppTheme.textSecondary),
          ],
        ),
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

  Widget _buildShareOption(
    BuildContext context,
    String platform,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              platform,
              style: GoogleFonts.montserrat(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
