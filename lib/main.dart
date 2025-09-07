import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.arknano.beaterbuddy.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const AudioPlayerScreen());
}

class PositionData {
  const PositionData(this.position, this.bufferedPosition, this.duration);

  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}

class WBTrack {
  final int id;
  final String title;
  final String pageURL;
  final String author;
  final int week;
  final int year;
  final String audioURL;

  WBTrack({
    required this.id,
    required this.title,
    required this.pageURL,
    required this.author,
    required this.week,
    required this.year,
    required this.audioURL,
  });
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  final FlutterTts tts = FlutterTts();
  int ttsLastPlayedIndex = -1;
  List<String> users = [""];

  Future<void> _speak(String text) async {
    await tts.setVolume(1);
    await tts.setSpeechRate(1);
    await tts.setPitch(1);
    await tts.awaitSpeakCompletion(true);

    if (text.isNotEmpty) {
      await tts.speak(text);
    }
  }

  Future<List<AudioSource>> _getPlaylist() async {
    final tracks = await _getAllUserTracks('Judgement Act');
    return [
      for (WBTrack track in tracks)
        AudioSource.uri(
          Uri.parse(track.audioURL),
          tag: MediaItem(
            id: track.id.toString(),
            title: track.title,
            artist: track.author,
            artUri: Uri.parse('assets/images/wb2024.png'),
          ),
        ),
    ];
  }

  Future<List<WBTrack>> _getAllUserTracks(String user) async {
    final jsonData = await getTrackData();
    final trackMaps =
        jsonData
            .whereType<Map<String, dynamic>>()
            .where((track) => track['author'] == user)
            .map((track) => Map<String, Object?>.from(track))
            .toList();

    trackMaps.sort((a, b) {
      final weekA = a['week'] as int? ?? 0;
      final weekB = b['week'] as int? ?? 0;
      return weekA.compareTo(weekB);
    });

    return [
      for (final {
            'id': id as int,
            'title': title as String,
            'link': link as String,
            'author': author as String,
            'week': week as int,
            'year': year as int,
            'url': url as String,
          }
          in trackMaps)
        WBTrack(
          id: id,
          title: title,
          pageURL: link,
          author: author,
          week: week,
          year: year,
          audioURL: url,
        ),
    ];
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    users = await getAllAuthors();
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.setAudioSources(await _getPlaylist());
    _audioPlayer.playbackEventStream.listen((state) {
      if (_audioPlayer.playing &&
          state.updatePosition.inSeconds == 0 &&
          state.currentIndex != ttsLastPlayedIndex) {
        print('Speaking new line for: ${state.currentIndex}');
        // _speak(
        //   '${_audioPlayer.sequence[state.currentIndex!].tag.title!} by ${_audioPlayer.sequence[state.currentIndex!].tag.artist!}',
        // );
        ttsLastPlayedIndex = state.currentIndex!;
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<List<dynamic>> getTrackData() async {
    final String jsonString = await rootBundle.loadString('assets/tracks.json');
    return json.decode(jsonString);
  }

  //AUTOCOMPLETE SEARCH BAR

  

  Future<List<String>> getAllAuthors() async {
    final jsonData = await getTrackData();

    final authors =
        jsonData
            .whereType<Map<String, dynamic>>()
            .map((track) => track['author']?.toString().trim() ?? '')
            .where((author) => author.isNotEmpty)
            .toSet()
            .toList();
    authors.sort();

    return authors;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
          leading: Image(
            image: const AssetImage('assets/images/favicon.png'),
            height: 40,
            width: 40,
          ),
          // actions: [IconButton(onPressed: () {}, icon: Icon(Icons.more_horiz))],
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 1.0],
              colors: [
                Color.fromARGB(255, 9, 27, 29),
                Color.fromARGB(255, 48, 139, 149),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<SequenceState?>(
                stream: _audioPlayer.sequenceStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  if (state?.sequence.isEmpty ?? true) {
                    return const SizedBox();
                  }
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
                    progress: positionData?.position ?? Duration.zero,
                    buffered: positionData?.bufferedPosition ?? Duration.zero,
                    total: positionData?.duration ?? Duration.zero,
                    onSeek: _audioPlayer.seek,
                  );
                },
              ),
              const SizedBox(height: 20),
              Controls(audioPlayer: _audioPlayer, tts: tts),
              AutocompleteBasicExample(options: users),
            ],
          ),
        ),
      ),
    );
  }
}

class MediaMetadata extends StatelessWidget {
  const MediaMetadata({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
  });

  final String imageUrl;
  final String title;
  final String artist;

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
        Text(
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
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
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
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

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

class AutocompleteBasicExample extends StatelessWidget {
  const AutocompleteBasicExample({super.key, required this.options});

  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return options.where((String option) {
          return option.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        debugPrint('You just selected $selection');
      },
    );
  }
}