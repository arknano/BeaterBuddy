import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/wb_track.dart';

class TrackRepository {
  Future<List<dynamic>> _loadJsonData() async {
    final String jsonString = await rootBundle.loadString('assets/tracks.json');
    return json.decode(jsonString);
  }

  Future<List<WBTrack>> getTracksByAuthor(String user) async {
    final jsonData = await _loadJsonData();
    final trackMaps =
        jsonData.whereType<Map<String, dynamic>>().where((track) => track['author'] == user).toList();

    trackMaps.sort((a, b) => (a['week'] ?? 0).compareTo(b['week'] ?? 0));

    return trackMaps.map((track) {
      return WBTrack(
        id: track['id'] as int,
        title: '(Week ${track['week']}) ${track['title']}',
        pageURL: track['link'] as String,
        author: track['author'] as String,
        week: track['week'] as int,
        year: track['year'] as int,
        audioURL: track['url'] as String,
      );
    }).toList();
  }

  Future<List<String>> getAllAuthors() async {
    final jsonData = await _loadJsonData();
    final authors = jsonData
        .whereType<Map<String, dynamic>>()
        .map((track) => track['author']?.toString().trim() ?? '')
        .where((author) => author.isNotEmpty)
        .toSet()
        .toList();
    authors.sort();
    return authors;
  }
}
