import 'dart:convert';

import 'package:dlna_player/model/lyrics.dart';
import 'package:dlna_player/service/genius_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _songUrl = 'https://genius.com/simon-and-garfunkel-the-boxer-lyrics';

String _searchResponse(String artist) => jsonEncode({
      'response': {
        'hits': [
          {
            'type': 'song',
            'result': {'artist_names': artist, 'url': _songUrl},
          },
        ],
      },
    });

void main() {
  test('search term is passed as encoded query parameter', () async {
    Uri? searchUri;
    final helper = GeniusHelper(
      client: MockClient((request) async {
        searchUri = request.url;
        return http.Response(jsonEncode({'response': {'hits': []}}), 200);
      }),
    );

    final lyrics = await helper.searchLyrics('Simon & Garfunkel', 'The Boxer #1');

    expect(searchUri!.queryParameters.keys, ['q']);
    expect(searchUri!.queryParameters['q'], 'The Boxer #1 Simon & Garfunkel');
    expect(lyrics.state, LyricsState.notFound);
  });

  test('single line lyrics are returned without error', () async {
    final helper = GeniusHelper(
      client: MockClient((request) async {
        if (request.url.host == 'api.genius.com') {
          return http.Response(_searchResponse('Simon & Garfunkel'), 200);
        }
        return http.Response('<div data-lyrics-container="true">Lie la lie</div>', 200);
      }),
    );

    final lyrics = await helper.searchLyrics('Simon & Garfunkel', 'The Boxer');

    expect(lyrics.state, LyricsState.success);
    expect(lyrics.text, 'Lie la lie');
  });

  test('non 200 search response returns error state', () async {
    final helper = GeniusHelper(
      client: MockClient((request) async => http.Response('', 401)),
    );

    final lyrics = await helper.searchLyrics('Artist', 'Title');

    expect(lyrics.state, LyricsState.error);
  });
}
