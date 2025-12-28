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

    trackMaps.sort((a, b) {
      int yearComparison = (a['year'] ?? 0).compareTo(b['year'] ?? 0);
      if (yearComparison != 0) return yearComparison;
      return (a['week'] ?? 0).compareTo(b['week'] ?? 0);
    });

    return trackMaps.map((track) {
      final String pageUrl = (track['link'] as String?) ?? '';
      String? authorUrl;
      if (pageUrl.isNotEmpty) {
        final idx = pageUrl.indexOf('/music');
        if (idx != -1) {
          authorUrl = pageUrl.substring(0, idx);
        }
      }

      return WBTrack(
        id: track['id'] as int,
        title: track['title'] as String,
        pageURL: pageUrl,
        author: track['author'] as String,
        authorURL: authorUrl,
        week: track['week'] as int,
        year: track['year'] as int,
        audioURL: track['url'] as String,
        imageURL: 'assets/images/albumart/${track['year']}.png',
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
