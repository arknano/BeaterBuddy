import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Controls extends StatelessWidget {
  const Controls({super.key, required this.audioPlayer, required this.tts});

  final AudioPlayer audioPlayer;
  final FlutterTts tts;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            audioPlayer.seekToPrevious();
            tts.stop();
          },
          iconSize: 60,
          color: Colors.white,
          icon: const Icon(
            Icons.skip_previous_rounded,
            shadows: [
              Shadow(
                color: Colors.black12,
                offset: Offset(2, 4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;

            if (!(playing ?? false)) {
              return IconButton(
                onPressed: () {
                  audioPlayer.play();
                },
                iconSize: 80,
                color: Colors.white,
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  shadows: [
                    Shadow(
                      color: Colors.black12,
                      offset: Offset(2, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                onPressed: () {
                  audioPlayer.pause();
                  tts.pause();
                },
                iconSize: 80,
                color: Colors.white,
                icon: const Icon(
                  Icons.pause_rounded,
                  shadows: [
                    Shadow(
                      color: Colors.black12,
                      offset: Offset(2, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              );
            }
            return const IconButton(
              onPressed: null,
              iconSize: 80,
              color: Colors.white,
              icon: Icon(
                Icons.play_arrow_rounded,
                shadows: [
                  Shadow(
                    color: Colors.black12,
                    offset: Offset(2, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          },
        ),
        IconButton(
          onPressed: () {
            audioPlayer.seekToNext();
            tts.stop();
          },
          iconSize: 60,
          color: Colors.white,
          icon: const Icon(
            Icons.skip_next_rounded,
            shadows: [
              Shadow(
                color: Colors.black12,
                offset: Offset(2, 4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
