import 'dart:convert';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dlna_player/model/lyrics.dart';
import 'package:flutter/foundation.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:http/http.dart' as http;

class GeniusHelper {
  var token = '';
  final patternRound = RegExp(r'\(.*\)');
  final patternSquare = RegExp(r'\[.*\]');
  final patternCurly = RegExp(r'\{.*\}');
  final patternAngle = RegExp(r'<.*>');
  final patternSlash = RegExp(r'/');
  final Map<String, String> headers = {};

  void setToken(String apiToken) {
    token = apiToken;
  }

  Future<Lyrics> searchLyrics(String artist, String title) async {
    // always set the authorization header
    headers.update('Authorization', (_) => 'Bearer $token', ifAbsent: () => 'Bearer $token');
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
      dynamic foundResult;
      for (var hit in hits) {
        final result = hit['result'];
        final foundArtist = result?['artist_names'];
        if (foundArtist != null) {
          final fuzzyRatio = partialRatio(foundArtist.toString().toLowerCase(), artist.toLowerCase());
          if (fuzzyRatio > 90) {
            debugPrint('Found artist: $foundArtist - $fuzzyRatio');
            foundResult = result;
            break;
          }
        }
      }
      if (foundResult == null) {
        return const Lyrics(LyricsState.empty);
      }
      final String responseBody = (await http.get(Uri.parse(Uri.encodeFull(foundResult?['url'])))).body;
      final BeautifulSoup bs = BeautifulSoup(responseBody.replaceAll('<br/>', '\n'));
      var lyrics = bs
          .findAll('div', attrs: {'data-lyrics-container': 'true'})
          .map((e) => e.getText().trim())
          .join('\n');
      if (lyrics.isEmpty) {
        return const Lyrics(LyricsState.empty);
      }
      final firstBreak = lyrics.indexOf('\n');
      debugPrint('Lyrics: ${lyrics.substring(0, firstBreak)}');
      return Lyrics(LyricsState.success, _cleanHeader(lyrics));
    }
    return const Lyrics(LyricsState.error);
  }

  String _cleanHeader(String lyrics) {
    // The lyrics at Genius.com have often text fragments at the beginning that don't belong to the lyrics.
    // The used tokens are not very consistent and vary from song to song.
    // I try to find the optimal position to remove this.
    final tokenL = 'Lyrics';
    final tokenLPos = lyrics.indexOf(tokenL);
    if (tokenLPos > 0) {
      var cleaned = lyrics.substring(tokenLPos + tokenL.length);
      final secondPos = cleaned.indexOf('Read More');
      if (secondPos > 0) {
        return cleaned.substring(secondPos + 9);
      }
      final tokenC = 'Contributors';
      final tokenCPos = cleaned.indexOf(tokenC);
      if (tokenCPos > 0) {
        cleaned = cleaned.substring(tokenCPos + tokenC.length);
      }
      // final tokenV = '[Verse';
      // final tokenVPos = cleaned.indexOf(tokenV);
      // if (tokenVPos > 0) {
      //   return cleaned.substring(tokenVPos);
      // }
      return cleaned;
    }
    return lyrics;
  }
}
