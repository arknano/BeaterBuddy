import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';
import '../models/wb_track.dart';

class AudioService {
  final AudioPlayer player = AudioPlayer();
  StreamSubscription<int?>? _indexSubscription;

  Future<List<AudioSource>> buildPlaylist(List<WBTrack> tracks) async {
    final audioSources = <AudioSource>[
      for (WBTrack track in tracks)
        AudioSource.uri(
          Uri.parse(track.audioURL),
          tag: MediaItem(
            id: track.id.toString(),
            title: track.title,
            artist: track.author,
            artUri: Uri.parse(track.imageURL),
            duration: const Duration(seconds: 1), // Placeholder; will be updated during playback
            extras: <String, dynamic>{
              'pageURL': track.pageURL,
              'authorURL': track.authorURL,
            },
          ),
        ),
    ];
    return audioSources;
  }

  void enablePreloading() {
    _indexSubscription?.cancel();
    // just_audio automatically preloads upcoming tracks in the sequence
    // This subscription just ensures the preloading is active
    _indexSubscription = player.currentIndexStream.listen((_) {
      // Index changed, just_audio is handling preload
    });
  }

  void dispose() {
    _indexSubscription?.cancel();
    player.dispose();
  }
}