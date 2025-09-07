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
  List<String> users = [""];

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioService.player.positionStream,
        _audioService.player.bufferedPositionStream,
        _audioService.player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    users = await _trackRepo.getAllAuthors();
    final tracks = await _trackRepo.getTracksByAuthor('Judgement Act');
    await _audioService.player.setLoopMode(LoopMode.all);
    await _audioService.player.setAudioSources(
      await _audioService.buildPlaylist(tracks),
    );

    _audioService.player.playbackEventStream.listen((state) {
      if (_audioService.player.playing &&
          state.updatePosition.inSeconds == 0 &&
          state.currentIndex != ttsLastPlayedIndex) {
        print('Speaking new line for: ${state.currentIndex}');
        // _ttsService.speak('${_audioService.player.sequence[state.currentIndex!].tag.title} by ${_audioService.player.sequence[state.currentIndex!].tag.artist}');
        ttsLastPlayedIndex = state.currentIndex!;
      }
    });
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
                if (state?.sequence.isEmpty ?? true) return const SizedBox();
                final metaData = state!.currentSource!.tag as MediaItem;
                return MediaMetadata(
                  imageUrl: metaData.artUri.toString(),
                  title: metaData.title,
                  artist: metaData.artist ?? '',
                );
              },
            ),
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
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
            AutocompleteBasic(options: users),
          ],
        ),
      ),
    );
  }
}
