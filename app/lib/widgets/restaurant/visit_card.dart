import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/restaurant_models.dart';

class VisitCard extends StatelessWidget {
  final Visit visit;

  const VisitCard({super.key, required this.visit});

  Future<void> _launchYouTube() async {
    final t = visit.timestampStart.floor();
    final url = Uri.parse('https://youtube.com/watch?v=${visit.videoId}&t=$t');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2, // elevation.md
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // borderRadius.lg
      child: Padding(
        padding: const EdgeInsets.all(16.0), // padding.md
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    visit.videoTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.colorScheme.secondary),
                  ),
                  child: Text(
                    visit.videoType ?? 'Appearance',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visit.guyIntro != null)
              Text(
                visit.guyIntro!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _launchYouTube,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Watch Full Segment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
