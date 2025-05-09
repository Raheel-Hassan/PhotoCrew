import 'package:flutter/material.dart';
import 'package:photocrew/widgets/custom_back_button.dart';
import 'package:url_launcher/url_launcher.dart';

class UserHelpSupportScreen extends StatelessWidget {
  const UserHelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: CustomBackButton(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 32),
            _buildHelpSection(
              context,
              title: 'Frequently Asked Questions',
              items: [
                const _HelpItem(
                  question: 'How do I book a photographer?',
                  answer:
                      'Browse photographers, view their portfolios, and click "Book Now" to start the booking process.',
                ),
                const _HelpItem(
                  question: 'What is the booking process?',
                  answer:
                      'Select your type of event, date, and time. You will receive a notification once the booking confirmed.',
                ),
                const _HelpItem(
                  question: 'Can I cancel a booking?',
                  answer:
                      'For cancellations, please contact the photographer directly. You can find their contact information in the your app at several places.',
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(
    BuildContext context, {
    required String title,
    required List<_HelpItem> items,
  }) {
    return Card(
       color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[200]
              : Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ExpansionPanelList.radio(
              children: items.map((item) {
                return ExpansionPanelRadio(
                  canTapOnHeader: true,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[100]
                          : Colors.grey[900],
                  value: item.question,
                  headerBuilder: (context, isExpanded) {
                    return ListTile(title: Text(item.question));
                  },
                  body: ListTile(
                    title: Text(item.answer),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    void launchPhone() async {
      final Uri phoneLaunchUri = Uri(
        scheme: 'tel',
        path: '+923080480000',
      );
      if (await canLaunchUrl(phoneLaunchUri)) {
        await launchUrl(phoneLaunchUri);
      }
    }

    void launchEmail() async {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'support@photocrew.com',
      );
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    }

    return Card(
       color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey[200]
              : Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact Us', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Support'),
              subtitle: const Text('support@photocrew.com'),
              onTap: launchEmail,
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Phone Support'),
              subtitle: const Text('+92 (308) 0480-000'),
              onTap: launchPhone,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem {
  final String question;
  final String answer;

  const _HelpItem({required this.question, required this.answer});
}
