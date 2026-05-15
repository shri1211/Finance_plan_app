import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('Introduction'),
            _buildParagraph(
              'Finance Tracker ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. We specifically address our use of SMS and notification scraping features required for the auto-capture of financial transactions.',
            ),
            const SizedBox(height: 20),
            
            _buildHeader('Information We Collect'),
            _buildSubHeader('1. SMS Data'),
            _buildParagraph(
              'To provide automated transaction tracking, our App requests permission to read your SMS messages.\n'
              '• What we collect: We only parse SMS messages from known financial institutions (banks, credit cards, digital wallets) to extract transaction amounts, merchant names, dates, and account identifiers.\n'
              '• What we DO NOT collect: We do not read, collect, or transmit personal SMS messages, OTPs, or messages from non-financial contacts.',
            ),
            
            _buildSubHeader('2. Notification Data'),
            _buildParagraph(
              'Our App requests Notification Access to auto-capture transactions from payment apps like Google Pay, PhonePe, and Paytm.\n'
              '• What we collect: We only process notifications from recognized payment applications to extract transaction details.\n'
              '• What we DO NOT collect: We do not store or transmit notifications from messaging apps, social media, or any non-financial applications.',
            ),

            _buildSubHeader('3. Personal Data'),
            _buildParagraph(
              'When you create an account, we may collect your name, email address, and authentication credentials.',
            ),
            const SizedBox(height: 20),

            _buildHeader('How We Use Your Information'),
            _buildParagraph(
              'The data we collect is used exclusively for the core functionality of the App:\n'
              '• To automatically log your financial transactions without manual entry.\n'
              '• To categorize your expenses and provide financial analytics.\n'
              '• To synchronize your financial data securely across your devices.',
            ),
            const SizedBox(height: 20),

            _buildHeader('Data Security and Storage'),
            _buildParagraph(
              'We prioritize the security of your financial data:\n'
              '• Local First: Transaction parsing from SMS and notifications happens entirely locally on your device. We do not send raw SMS or notification data to our servers.\n'
              '• Encryption: Only parsed, structured transaction data is securely transmitted to our backend using HTTPS and encrypted at rest.\n'
              '• No Data Selling: We do not sell, rent, or share your personal or financial data with third parties for marketing or advertising purposes.',
            ),
            const SizedBox(height: 20),

            _buildHeader('User Control and Permissions'),
            _buildParagraph(
              'You have full control over the permissions granted to the App:\n'
              '• You can enable or disable SMS Auto-Capture and UPI Notification Capture at any time from the App\'s Profile settings or your device\'s operating system settings.\n'
              '• The App will continue to function (allowing manual transaction entry) even if you deny these permissions.',
            ),
            const SizedBox(height: 20),

            _buildHeader('Contact Us'),
            _buildParagraph(
              'If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at support@financetracker.com.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }
}
