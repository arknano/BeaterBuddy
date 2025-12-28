import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CreditsDialog extends StatelessWidget {
  const CreditsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 9, 27, 29),
      title: const Text('BeaterBuddy', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Application developed by arknano (Judgement Act)\nWith assistance from Mission Crossing and Trash80\n',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const Text(
                'All of the content presented within BeaterBuddy is publically available on WeeklyBeats, but if you\'d like to opt-out of your tracks being available in the app for any reason, please file an issue on GitHub including a link to your WeeklyBeats profile.\n\nBeaterBuddy is created with the support but not the endorsement of the WeeklyBeats organisers.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  await launchUrlString(
                    'https://github.com/arknano/BeaterBuddy',
                  );
                },
                child: const Text(
                  'View on GitHub',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 238, 255),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  await launchUrlString('https://weeklybeats.com');
                },
                child: const Text(
                  'Visit WeeklyBeats',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 238, 255),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
