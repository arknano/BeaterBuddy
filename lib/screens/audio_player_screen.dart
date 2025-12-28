import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import '../models/position_data.dart';
import '../models/wb_track.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import '../services/track_repository.dart';
import '../widgets/media_metadata.dart';
import '../widgets/controls.dart';
// inline author selector dialog is used instead of AutocompleteBasic
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

  List<WBTrack> _currentTracks = [];
  int? _currentIndex;
  late StreamSubscription<int?> _indexSub;

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

  setState(() {
    _currentTracks = tracks;
  });

  await _audioService.player.seek(Duration.zero, index: 0);
}


  @override
  void initState() {
    super.initState();
    _init();
    _indexSub = _audioService.player.currentIndexStream.listen((i) {
      setState(() {
        _currentIndex = i;
      });
    });
  }

  Future<void> _init() async {
    final authors = await _trackRepo.getAllAuthors();
    setState(() {
      users = authors; // populate autocomplete
    });

    await _audioService.player.setLoopMode(LoopMode.all);
  }

  @override
  void dispose() {
    _indexSub.cancel();
    _audioService.player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      //HEADER
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

        //MEDIA METADATA
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
                      'Select an artist to load tracks',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }
                final tag = state!.currentSource!.tag;
                if (tag is! MediaItem) return const SizedBox();
                
                // Get year and week from current track
                final currentTrackIndex = state.currentIndex ?? -1;
                int? year;
                int? week;
                if (currentTrackIndex >= 0 && currentTrackIndex < _currentTracks.length) {
                  year = _currentTracks[currentTrackIndex].year;
                  week = _currentTracks[currentTrackIndex].week;
                }
                
                return MediaMetadata(
                  imageUrl: tag.artUri.toString(),
                  title: tag.title,
                  artist: tag.artist ?? '',
                    titleUrl: tag.extras?['pageURL'] as String?,
                    artistUrl: (tag.extras?['authorURL'] as String?) ?? (tag.extras?['pageURL'] as String?),
                    year: year,
                    week: week,
                );
              },
            ),

            //TRACK PROGRESS BAR
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

            //CONTROLS
            const SizedBox(height: 20),
            Controls(audioPlayer: _audioService.player, tts: _ttsService.tts),

            // PLAYLIST
            const SizedBox(height: 12),
            if (_currentTracks.isNotEmpty)
              Container(
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color.fromARGB(255, 0, 238, 255), width: 1),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black26,
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                  child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _currentTracks.length,
                        itemBuilder: (context, index) {
                          final track = _currentTracks[index];
                          final isPlaying = _currentIndex == index;
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            title: Text(
                              track.title,
                              style: TextStyle(
                                color: isPlaying ? const Color.fromARGB(255, 0, 238, 255) : Colors.white,
                                fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              'Week ${track.week} · ${track.year}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: isPlaying ? const Icon(Icons.play_arrow, color: Color.fromARGB(255, 0, 238, 255)) : null,
                            onTap: () async {
                              _ttsService.tts.stop();
                              await _audioService.player.seek(Duration.zero, index: index);
                              await _audioService.player.play();
                            },
                          );
                        },
                      ),
                    ),
              ),

            const SizedBox.shrink(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final authors = await _trackRepo.getAllAuthors();
          showDialog<void>(
            context: context,
            builder: (dialogContext) {
              final TextEditingController controller = TextEditingController();
              List<String> filtered = List.from(authors);
              return StatefulBuilder(builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: const Color.fromARGB(255, 9, 27, 29),
                  title: const Text('Select Artist', style: TextStyle(color: Colors.white)),
                  content: SizedBox(
                    width: 360,
                    height: 260,
                    child: Column(
                      children: [
                        TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search artists',
                            hintStyle: TextStyle(color: Colors.white54),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color.fromARGB(255, 0, 238, 255)),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              filtered = authors
                                  .where((a) => a.toLowerCase().contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 9, 27, 29),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: filtered.isEmpty
                                ? const Center(child: Text('No artists', style: TextStyle(color: Colors.white54)))
                                : ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final option = filtered[index];
                                      return ListTile(
                                        dense: true,
                                        title: Text(option, style: const TextStyle(color: Colors.white)),
                                        onTap: () {
                                          Navigator.of(dialogContext).pop();
                                          _updatePlaylistForAuthor(option);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        final selection = authors[Random().nextInt(authors.length)];
                        Navigator.of(dialogContext).pop();
                        _updatePlaylistForAuthor(selection);
                      },
                      child: const Text('Random', style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Close', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                );
              });
            },
          );
        },
        backgroundColor: const Color.fromARGB(255, 0, 238, 255),
        icon: const Icon(Icons.person_search, color: Colors.black87),
        label: const Text('Choose Artist', style: TextStyle(color: Colors.black87)),
      ),
    );
  }
}
