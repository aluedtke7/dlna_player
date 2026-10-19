import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/model/content_class.dart';
import 'package:upnp2/upnp.dart';
import 'package:xml/xml.dart';

class DlnaService {
  static Service? directoryService;
  static Action? browseAction;

  static Future<XmlDocument> browse(String id, {int maxCount = 0, int startIdx = 0}) async {
    final browseMap = await _browseRaw(id, maxCount: maxCount, startIdx: startIdx);
    return XmlDocument.parse(browseMap['Result'] ?? '');
  }

  static Future<Map<String, String>> _browseRaw(String id, {int maxCount = 0, int startIdx = 0}) async {
    if (browseAction == null) {
      return {};
    }
    try {
      return await browseAction!.invoke({
        'ObjectID': id,
        'BrowseFlag': 'BrowseDirectChildren',
        'Filter': '*',
        'StartingIndex': startIdx,
        'RequestedCount': maxCount,
        'SortCriteria': '',
      });
    } catch (e) {
      throw Exception('Error browsing device: empty result');
    }
  }

  static Future<List<RawContent>> browseAll(String id) async {
    const chunkSize = 1000;
    var start = 0;
    final List<RawContent> tracks = [];
    while (true) {
      final browseMap = await _browseRaw(id, maxCount: chunkSize, startIdx: start);
      final browseDoc = XmlDocument.parse(browseMap['Result'] ?? '');
      tracks.addAll(parseContainer(browseDoc));
      tracks.addAll(parseTracks(browseDoc));
      // Paging is driven by the server's counts, not by the parsed items,
      // because unsupported items are filtered out while parsing.
      final returned = int.tryParse(browseMap['NumberReturned'] ?? '') ?? 0;
      final total = int.tryParse(browseMap['TotalMatches'] ?? '') ?? 0;
      start += returned;
      // TotalMatches may be 0 when the server doesn't know it
      final hasMore = total > 0 ? start < total : returned == chunkSize;
      if (returned == 0 || !hasMore) {
        return tracks;
      }
    }
  }

  static List<RawContent> parseContainer(XmlDocument doc) {
    final c = doc.findAllElements('container');
    List<RawContent> container = [];
    for (var element in c) {
      final id = element.getAttribute('id') ?? '';
      final parentId = element.getAttribute('parentID') ?? '';
      final numTracks = int.parse(element.getAttribute('childCount') ?? '0');
      final title = element.getElement('dc:title')?.innerText ?? '';
      final cl = element.getElement('upnp:class')?.innerText ?? '';
      final clenum = cl.toContentClass();
      final artist = element.getElement('upnp:artist')?.innerText ?? '';
      final genre = element.getElement('upnp:genre')?.innerText ?? '';
      final albumUri = element.getElement('upnp:albumArtURI')?.innerText;
      container.add(RawContent(
        id: id,
        parentId: parentId,
        artist: artist,
        classType: clenum,
        title: title,
        genre: genre,
        numTracks: numTracks,
        albumArt: albumUri,
      ));
    }
    return container;
  }

  static List<RawContent> parseTracks(XmlDocument doc) {
    final items = doc.findAllElements('item');
    List<RawContent> tracks = [];
    for (var element in items) {
      final cl = element.getElement('upnp:class')?.innerText ?? '';
      final clenum = cl.toContentClass();
      if (clenum == ContentClass.track) {
        final id = element.getAttribute('id') ?? '';
        final parentId = element.getAttribute('parentID') ?? '';
        final title = element.getElement('dc:title')?.innerText ?? '';
        final artist =
            element.getElement('dc:creator')?.innerText ?? element.getElement('upnp:artist')?.innerText ?? '';
        final album = element.getElement('upnp:album')?.innerText ?? '';
        final genre = element.getElement('upnp:genre')?.innerText ?? '';
        final trackNum = int.tryParse(element.getElement('upnp:originalTrackNumber')?.innerText ?? '0') ?? 0;
        final date = DateTime.tryParse(element.getElement('dc:date')?.innerText ?? '');
        final albumUri = element.getElement('upnp:albumArtURI')?.innerText;
        final res = element.getElement('res');
        var trackUri = '';
        var duration = '';
        if (res != null) {
          trackUri = res.innerText;
          duration = res.getAttribute('duration') ?? '';
        }
        if (trackUri.isNotEmpty) {
          tracks.add(
            RawContent(
              id: id,
              parentId: parentId,
              classType: ContentClass.track,
              artist: artist,
              title: title,
              album: album,
              genre: genre,
              date: date,
              trackNum: trackNum,
              duration: duration,
              trackUrl: trackUri,
              albumArt: albumUri,
            ),
          );
        }
      }
    }
    return tracks;
  }
}
