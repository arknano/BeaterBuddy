import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/wb_track.dart';

class AudioService {
  final AudioPlayer player = AudioPlayer();

  Future<List<AudioSource>> buildPlaylist(List<WBTrack> tracks) async {
    return [
      for (WBTrack track in tracks)
        AudioSource.uri(
          Uri.parse(track.audioURL),
          tag: MediaItem(
            id: track.id.toString(),
            title: track.title,
            artist: track.author,
            artUri: Uri.parse(track.imageURL),
            extras: <String, dynamic>{
              'pageURL': track.pageURL,
              'authorURL': track.authorURL,
            },
          ),
        ),
    ];
  }
}
