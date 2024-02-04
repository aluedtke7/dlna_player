import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:beautiful_soup_dart/beautiful_soup.dart';

import 'package:dlna_player/model/lyrics.dart';

class GeniusHelper {
  final String token = const String.fromEnvironment('GENIUS_TOKEN', defaultValue: '');
  final patternRound = RegExp(r'\(.*\)');
  final patternSquare = RegExp(r'\[.*\]');
  final patternCurly = RegExp(r'\{.*\}');
  final patternAngle = RegExp(r'<.*>');
  final patternSlash = RegExp(r'/');
  final Map<String, String> headers = {};

  GeniusHelper() {
    headers.putIfAbsent('Authorization', () => 'Bearer $token');
  }

  Future<Lyrics> searchLyrics(String artist, String title) async {
    // make the search term more compatible with Genius
    var searchTerm = '$title $artist'
        .replaceAll(patternAngle, '')
        .replaceAll(patternCurly, '')
        .replaceAll(patternRound, '')
        .replaceAll(patternSquare, '')
        .replaceAll(patternSlash, '');

    var request = http.Request('GET', Uri.parse('https://api.genius.com/search?q=$searchTerm'));
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var body = await response.stream.bytesToString();
      var decoded = jsonDecode(body) as Map<String, dynamic>;
      final resp = decoded['response'];
      List<dynamic> topHits = resp['hits'];
      List<Map<String, dynamic>> hits = [];
      for (var hit in topHits) {
        if (hit['type'] != null) {
          if (hit['type'] == 'song') {
            hits.add(hit);
          }
        }
      }
      if (hits.isEmpty) {
        return const Lyrics(LyricsState.notFound);
      }
      final foundResult = hits[0]['result'];
      final foundArtist = foundResult?['artist_names'];
      if (foundArtist != null && !foundArtist.toString().toLowerCase().contains(artist.toLowerCase())) {
        return const Lyrics(LyricsState.empty);
      }
      final String responseBody = (await http.get(Uri.parse(Uri.encodeFull(foundResult?['url'])))).body;
      final BeautifulSoup bs = BeautifulSoup(responseBody.replaceAll('<br/>', '\n'));
      final lyrics = bs.findAll('div', class_: 'Lyrics__Container').map((e) => e.getText().trim()).join('\n');
      if (lyrics.isEmpty) {
        return const Lyrics(LyricsState.empty);
      }
      return Lyrics(LyricsState.success, lyrics);
    }
    return const Lyrics(LyricsState.error);
  }
}
