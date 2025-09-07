import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class CustomProgressBar extends StatelessWidget {
  const CustomProgressBar({
    super.key,
    required this.progress,
    required this.buffered,
    required this.total,
    required this.onSeek,
  });

  final Duration progress;
  final Duration buffered;
  final Duration total;
  final void Function(Duration) onSeek;

  @override
  Widget build(BuildContext context) {
    return ProgressBar(
      barHeight: 8,
      baseBarColor: Colors.grey[600],
      bufferedBarColor: Colors.grey,
      progressBarColor: const Color.fromARGB(255, 0, 238, 255),
      thumbColor: const Color.fromARGB(255, 0, 238, 255),
      timeLabelTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: Colors.black12,
            offset: Offset(2, 4),
            blurRadius: 4,
          ),
        ],
      ),
      progress: progress,
      buffered: buffered,
      total: total,
      onSeek: onSeek,
    );
  }
}
