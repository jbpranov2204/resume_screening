import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resume_screening/analysis.dart';
import 'package:resume_screening/candidates.dart';
import 'package:resume_screening/contact.dart';
import 'package:resume_screening/overview.dart';
import 'package:resume_screening/skills.dart';
import 'package:url_launcher/url_launcher.dart';



class CandidateDetailsTabBar extends StatefulWidget {
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

  const CandidateDetailsTabBar({
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
  _CandidateDetailsTabBarState createState() => _CandidateDetailsTabBarState();
}

class _CandidateDetailsTabBarState extends State<CandidateDetailsTabBar>
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
                title: _isAppBarExpanded ? null : null,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
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
            OverviewTab(
              name: widget.name,
              jobTitle: widget.jobTitle,
              company: widget.company,
              submittedDate: widget.submittedDate,
              experienceSummary: widget.experienceSummary,
              about: widget.about,
              score: widget.score,
              likelihood: widget.likelihood,
              probability: widget.probability,
              selectionReason: widget.selectionReason,
              scoreBreakdown: widget.scoreBreakdown,
              improvementSuggestions: widget.improvementSuggestions,
            ),
            SkillsTab(skills: widget.skills),
            AnalysisTab(
              grade: widget.grade,
              scoreBreakdown: widget.scoreBreakdown,
              likelihood: widget.likelihood,
              probability: widget.probability,
              selectionReason: widget.selectionReason,
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
      ),
    );
  }
}
