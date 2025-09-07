import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import '../models/position_data.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import '../services/track_repository.dart';
import '../widgets/media_metadata.dart';
import '../widgets/controls.dart';
import '../widgets/autocomplete_basic.dart';
import '../widgets/custom_progress_bar.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioService _audioService = AudioService();
  final TtsService _ttsService = TtsService();
  final TrackRepository _trackRepo = TrackRepository();
  int ttsLastPlayedIndex = -1;
  late List<String> users = [""];

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioService.player.positionStream,
        _audioService.player.bufferedPositionStream,
        _audioService.player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

Future<void> _updatePlaylistForAuthor(String author) async {
  final tracks = await _trackRepo.getTracksByAuthor(author);
  final audioSources = await _audioService.buildPlaylist(tracks);

  _ttsService.tts.stop();
  await _audioService.player.stop();

  await _audioService.player.setAudioSources(audioSources);

  await _audioService.player.seek(Duration.zero, index: 0);
}


  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Future<void> _init() async {
    final authors = await _trackRepo.getAllAuthors();
    setState(() {
      users = authors; // populate autocomplete
    });

    await _audioService.player.setLoopMode(LoopMode.all);
  }

  @override
  void dispose() {
    _audioService.player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'BeaterBuddy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        leading: const Image(
          image: AssetImage('assets/images/favicon.png'),
          height: 40,
          width: 40,
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 9, 27, 29),
              Color.fromARGB(255, 48, 139, 149),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<SequenceState?>(
              stream: _audioService.player.sequenceStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                if (state?.sequence.isEmpty ?? true) {
                  return const Center(
                    child: Text(
                      'Select an author to load tracks',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }
                final tag = state!.currentSource!.tag;
                if (tag is! MediaItem) return const SizedBox();
                return MediaMetadata(
                  imageUrl: tag.artUri.toString(),
                  title: tag.title,
                  artist: tag.artist ?? '',
                );
              },
            ),
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
                if (_audioService.player.sequence.isEmpty) {
                }
                return CustomProgressBar(
                  progress: positionData?.position ?? Duration.zero,
                  buffered: positionData?.bufferedPosition ?? Duration.zero,
                  total: positionData?.duration ?? Duration.zero,
                  onSeek: _audioService.player.seek,
                );
              },
            ),
            const SizedBox(height: 20),
            Controls(audioPlayer: _audioService.player, tts: _ttsService.tts),
            FutureBuilder<List<String>>(
              future: _trackRepo.getAllAuthors(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final authors = snapshot.data!;
                return AutocompleteBasic(
                  options: authors,
                  onSelected: (String selection) {
                    debugPrint('Selected author: $selection');
                    _updatePlaylistForAuthor(selection);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
