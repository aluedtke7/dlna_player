import 'package:dlna_player/service/dlna_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upnp2/upnp.dart';

/// Serves a fixed list of DIDL items in pages, like a ContentDirectory Browse action.
class FakeBrowseAction extends Action {
  FakeBrowseAction(this.items, {this.pageLimit, this.reportTotal = true});

  final List<String> items;
  final int? pageLimit;
  final bool reportTotal;
  final requestedStarts = <int>[];

  @override
  Future<Map<String, String>> invoke(Map<String, dynamic> args) async {
    final start = args['StartingIndex'] as int;
    var count = args['RequestedCount'] as int;
    if (pageLimit != null && count > pageLimit!) count = pageLimit!;
    requestedStarts.add(start);
    final page = items.skip(start).take(count).toList();
    return {
      'Result': '<DIDL-Lite xmlns:dc="http://purl.org/dc/elements/1.1/" '
          'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">${page.join()}</DIDL-Lite>',
      'NumberReturned': '${page.length}',
      'TotalMatches': reportTotal ? '${items.length}' : '0',
    };
  }
}

String _track(int i) => '<item id="t$i" parentID="p"><dc:title>Track $i</dc:title>'
    '<upnp:class>object.item.audioItem.musicTrack</upnp:class>'
    '<res duration="0:03:00.000">http://server/t$i.mp3</res></item>';

String _video(int i) => '<item id="v$i" parentID="p"><dc:title>Video $i</dc:title>'
    '<upnp:class>object.item.videoItem</upnp:class>'
    '<res>http://server/v$i.mp4</res></item>';

void main() {
  tearDown(() => DlnaService.browseAction = null);

  test('browseAll keeps paging when a page contains filtered items', () async {
    final items = [_video(0), for (var i = 1; i < 1500; i++) _track(i)];
    DlnaService.browseAction = FakeBrowseAction(items);

    final tracks = await DlnaService.browseAll('p');

    expect(tracks.length, 1499);
    expect(tracks.last.id, 't1499');
  });

  test('browseAll follows pages smaller than the requested chunk', () async {
    final items = [for (var i = 0; i < 1200; i++) _track(i)];
    final action = FakeBrowseAction(items, pageLimit: 500);
    DlnaService.browseAction = action;

    final tracks = await DlnaService.browseAll('p');

    expect(tracks.length, 1200);
    expect(action.requestedStarts, [0, 500, 1000]);
  });

  test('browseAll pages by full chunks when total is unknown', () async {
    final items = [for (var i = 0; i < 1500; i++) _track(i)];
    final action = FakeBrowseAction(items, reportTotal: false);
    DlnaService.browseAction = action;

    final tracks = await DlnaService.browseAll('p');

    expect(tracks.length, 1500);
    expect(action.requestedStarts, [0, 1000]);
  });
}
