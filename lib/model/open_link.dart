import 'package:url_launcher/url_launcher.dart';

enum Website {
  discogs,
  musicbrainz,
  wikipedia,
}

class OpenLink {
  static void openSite(Website site, String artist) {
    switch (site) {
      case Website.discogs:
        var uri = Uri(scheme: 'https', host: 'discogs.com', path: 'search', queryParameters: {
          'type': 'artist',
          'q': artist,
        });
        launchUrl(uri, mode: LaunchMode.externalApplication);
        break;
      case Website.musicbrainz:
        var uri = Uri(scheme: 'https', host: 'musicbrainz.org', path: 'search', queryParameters: {
          'method': 'indexed',
          'type': 'artist',
          'query': artist,
        });
        launchUrl(uri, mode: LaunchMode.externalApplication);
        break;
      case Website.wikipedia:
        var uri = Uri(scheme: 'https', host: 'en.wikipedia.org', path: 'w/index.php', queryParameters: {
          'fulltext': '1',
          'search': artist,
        });
        launchUrl(uri, mode: LaunchMode.externalApplication);
        break;
    }
  }
}
