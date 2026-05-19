import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key, this.onAgree});

  final VoidCallback? onAgree;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A0B),
        foregroundColor: const Color(0xFF7DEEFF),
        elevation: 0,
        title: const Text(
          'Legal Terms',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'EventTab',
                style: TextStyle(
                  color: Color(0xFF7DEEFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terms and Conditions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      number: '01.',
                      title: 'ACCEPTANCE OF TERMS',
                      content:
                          'Welcome to EventTab. By accessing or using our platform, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. This agreement constitutes a legally binding contract between you and Elite Global Esports Inc.',
                    ),
                    const SizedBox(height: 28),
                    _buildSection(
                      number: '02.',
                      title: 'ELIGIBILITY',
                      content: '',
                      children: [
                        _buildSubSection(
                          icon: Icons.cake_outlined,
                          title: 'Age Requirement',
                          content:
                              'Participants must be at least 18 years of age or the age of majority in their jurisdiction. Minors require notarized parental consent.',
                        ),
                        const SizedBox(height: 16),
                        _buildSubSection(
                          icon: Icons.public,
                          title: 'Regional Restrictions',
                          content:
                              'Access is prohibited in jurisdictions where real-money competitive gaming is restricted by local law. Users are responsible for local compliance.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSection(
                      number: '03.',
                      title: 'USER CONDUCT',
                      content:
                          'Users must maintain respectful behavior, refrain from cheating or exploiting platform vulnerabilities, and comply with all applicable laws. Violations may result in account suspension or termination.',
                    ),
                    const SizedBox(height: 28),
                    _buildSection(
                      number: '04.',
                      title: 'PRIVACY & DATA',
                      content:
                          'We collect and process user data in accordance with our Privacy Policy. By using EventTab, you consent to data collection for account management, event participation, and platform improvement.',
                    ),
                    const SizedBox(height: 28),
                    _buildSection(
                      number: '05.',
                      title: 'LIMITATION OF LIABILITY',
                      content:
                          'EventTab is provided "as is" without warranties. We are not liable for indirect, incidental, or consequential damages arising from platform use.',
                    ),
                    const SizedBox(height: 28),
                    const Center(
                      child: Text(
                        'END OF LEGAL DOCUMENTATION',
                        style: TextStyle(
                          color: Color(0xFF4A4C50),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF2B2D31), width: 1),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7CE1EF), Color(0xFF00C5D9)],
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          onAgree?.call();
                          Navigator.of(context).pop(true);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF061014),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text(
                          'I AGREE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF797B81),
                    ),
                    child: const Text(
                      'CANCEL & EXIT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number $title',
          style: const TextStyle(
            color: Color(0xFF7DEEFF),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF9FA1A5),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
        if (children != null) ...[
          const SizedBox(height: 16),
          ...children,
        ],
      ],
    );
  }

  Widget _buildSubSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1012),
        border: Border.all(color: const Color(0xFF2B2D31)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFFF7A18),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF9FA1A5),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
