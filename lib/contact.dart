import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// Import the AppTheme from a common file
import 'candidates_details.dart';

class ContactTab extends StatelessWidget {
  final String email;
  final String phone;
  final String linkedin;
  final String github;
  final String company;
  final String jobTitle;
  final String submittedDate;
  final Function? sendEmail;

  const ContactTab({
    Key? key,
    required this.email,
    required this.phone,
    required this.linkedin,
    required this.github,
    required this.company,
    required this.jobTitle,
    required this.submittedDate,
    this.sendEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Information', style: AppTheme.headingStyle),
          SizedBox(height: 16),

          // Personal Contact card
          _buildInfoCard('Personal Contact', [
            if (email.isNotEmpty)
              _buildContactItem(
                'Email',
                email,
                Icons.email,
                AppTheme.primaryColor,
                () => launchUrl(Uri.parse('mailto:$email')),
              ),
            if (phone.isNotEmpty)
              _buildContactItem(
                'Phone',
                phone,
                Icons.phone,
                Colors.green,
                () => launchUrl(Uri.parse('tel:$phone')),
              ),
            if (linkedin.isNotEmpty)
              _buildContactItem(
                'LinkedIn',
                linkedin,
                Icons.work,
                Colors.blue,
                () => launchUrl(Uri.parse(_normalizeUrl(linkedin))),
              ),
            if (github.isNotEmpty)
              _buildContactItem(
                'GitHub',
                github,
                Icons.code,
                Colors.purple,
                () => launchUrl(Uri.parse(_normalizeUrl(github))),
              ),
            if (email.isEmpty &&
                phone.isEmpty &&
                linkedin.isEmpty &&
                github.isEmpty)
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

          // Company information card - separate from the other cards
          _buildInfoCard('Company Information', [
            _buildDetailItem(Icons.business, 'Company', company),
            _buildDetailItem(Icons.work, 'Position', jobTitle),
            _buildDetailItem(
              Icons.calendar_today,
              'Application Date',
              submittedDate,
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
