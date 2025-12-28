import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MediaMetadata extends StatelessWidget {
  const MediaMetadata({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
    this.titleUrl,
    this.artistUrl,
  });

  final String imageUrl;
  final String title;
  final String artist;
  final String? titleUrl;
  final String? artistUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(2, 4),
                blurRadius: 4,
              ),
            ],
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image(
              image: AssetImage(imageUrl),
              height: 300,
              width: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: titleUrl != null
              ? () async {
                  await launchUrlString(titleUrl!);
                }
              : null,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black12,
                  offset: Offset(2, 4),
                  blurRadius: 4,
                ),
              ],
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: artistUrl != null
              ? () async {
                  await launchUrlString(artistUrl!);
                }
              : null,
          child: Text(
            artist,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black12,
                  offset: Offset(2, 4),
                  blurRadius: 4,
                ),
              ],
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
