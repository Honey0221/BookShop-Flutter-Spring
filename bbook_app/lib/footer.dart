import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final Color primaryColor;
  final Color primaryLightColor;

  const Footer({
    super.key,
    this.primaryColor = const Color(0xFF76C97F),
    this.primaryLightColor = const Color(0xFFE8F5E9),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primaryLightColor,
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'B-Book',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(height: 28),
                      Text(
                        'Email: info@builders.com',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Phone: +82 (02) 555-1234',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFooterSection('Platform', [
                        'Plans & Pricing',
                        'About Us',
                        'Business',
                      ]),
                      _buildFooterSection('Company', [
                        'Blog',
                        'Careers',
                        'News',
                      ]),
                      _buildFooterSection('Resources', [
                        'Documentation',
                        'Papers',
                        'Conference',
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Divider(height: 1, color: Colors.grey.shade300),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegalLink('Terms of Service'),
                    _buildLegalLink('Privacy Policy'),
                    _buildLegalLink('Cookies'),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '© 2025 Builders Book. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(String title, List<String> links) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          ...links.map((link) => Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              child: Text(
                link,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

