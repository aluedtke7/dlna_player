import 'package:audioplayers/audioplayers.dart';
import 'package:dlna_player/application.dart';
import 'package:dlna_player/component/card/album_card.dart';
import 'package:dlna_player/component/card/container_card.dart';
import 'package:dlna_player/component/card/lyrics_card.dart';
import 'package:dlna_player/component/card/progress_card.dart';
import 'package:dlna_player/component/card/track_card.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/keyboard_scaffold.dart';
import 'package:dlna_player/component/player_widget.dart';
import 'package:dlna_player/component/statics.dart';
import 'package:dlna_player/component/theme_options.dart';
import 'package:dlna_player/model/content_arguments.dart';
import 'package:dlna_player/model/content_class.dart';
import 'package:dlna_player/model/open_link.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:dlna_player/service/dlna_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

class ContentPage extends ConsumerStatefulWidget {
  const ContentPage({super.key});

  static const routeName = '/container';

  @override
  ConsumerState<ContentPage> createState() => _ContentPageState();
}

class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

class ClearSearchIntent extends Intent {
  const ClearSearchIntent();
}

class _ContentPageState extends ConsumerState<ContentPage> {
  var searchTerm = '';
  var currentTrackTitle = '';
  var showPlayerWidget = true;
  var searching = false;
  var searchIdx = -1;
  late SharedPreferences prefs;
  final textNode = FocusNode();
  final maxCrossAxisExtent = 400.0;
  final landscapeWidth = 600;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    _loadPrefInstance();
    scrollController = ScrollController();
  }

  Future<void> _loadPrefInstance() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    textNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  String buildTitle(String parent, String title) {
    return (parent.isNotEmpty ? '$parent - ' : '') + title;
  }

  @override
  Widget build(BuildContext context) {
    ContentClass type;
    final mq = MediaQuery.of(context);
    final trackRef = ref.watch(trackProvider);
    final playListRef = ref.watch(playlistProvider);
    final playListIndexRef = ref.watch(playlistIndexProvider);
    final argument = ModalRoute.of(context)!.settings.arguments as ContentArguments;
    if (argument.content.isEmpty) {
      type = ContentClass.none;
    } else {
      type = argument.content.first.classType;
      if (type == ContentClass.none && argument.content.length > 1) {
        type = argument.content[1].classType;
      }
    }
    final typeName = i18n(context).content_class(type.toString());
    // build filtered list based on search term
    final List<RawContent> selItems;
    final double mainAxisExtend;
    switch (type) {
      case ContentClass.album:
        selItems =
            argument.content
                .where(
                  (el) => el.title.toLowerCase().contains(searchTerm) || el.artist.toLowerCase().contains(searchTerm),
                )
                .toList();
        mainAxisExtend = 110;
        break;
      case ContentClass.artist:
        selItems =
            argument.content
                .where(
                  (el) => el.title.toLowerCase().contains(searchTerm) || el.genre.toLowerCase().contains(searchTerm),
                )
                .toList();
        mainAxisExtend = 110;
        break;
      case ContentClass.genre:
      case ContentClass.playlist:
        selItems = argument.content.where((el) => el.title.toLowerCase().contains(searchTerm)).toList();
        mainAxisExtend = 110;
        break;
      case ContentClass.folder:
        selItems = argument.content.where((el) => el.title.toLowerCase().contains(searchTerm)).toList();
        mainAxisExtend = 110;
        break;
      case ContentClass.track:
        selItems =
            argument.content
                .where(
                  (el) =>
                      el.title.toLowerCase().contains(searchTerm) ||
                      el.artist.toLowerCase().contains(searchTerm) ||
                      el.album.toLowerCase().contains(searchTerm),
                )
                .toList();
        mainAxisExtend = 100;
        break;
      default:
        selItems = argument.content;
        mainAxisExtend = 120;
    }
    final trackGrid = buildTrackGrid(mainAxisExtend, selItems, argument, typeName, context);
    late int numberOfColumns;
    // When lyrics are being displayed, we only have 2/3 of the width for the track grid
    if (mq.size.width >= landscapeWidth && ref.read(showLyricsProvider)) {
      numberOfColumns = (mq.size.width * 2 / 3 / maxCrossAxisExtent).ceil();
    } else {
      numberOfColumns = (mq.size.width / maxCrossAxisExtent).ceil();
    }

    // The ScrollController must be connected to the UI in order to work. We check also if the length of the play list
    // is the same as the list being displayed. This is not totally correct, but it will avoid scroll events when
    // the two lists don't match in length.
    if (scrollController.hasClients && selItems.length == playListRef.length) {
      var idx = (playListIndexRef.toDouble() ~/ numberOfColumns) * 100.0;
      scrollController.animateTo(idx, duration: Duration(milliseconds: 1000), curve: Curves.easeInOut);
    }

    void openSearchDialog() {
      Statics.showSearchDialog(context, i18n(context).content_search_for, searchTerm).then((value) {
        if (value != null) {
          setState(() {
            searchTerm = value.toLowerCase();
          });
        }
      });
    }

    void clearSearch() {
      if (searchTerm.isNotEmpty) {
        setState(() {
          searchTerm = '';
        });
      }
    }

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const OpenSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX): const ClearSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          OpenSearchIntent: CallbackAction<OpenSearchIntent>(onInvoke: (intent) => openSearchDialog()),
          ClearSearchIntent: CallbackAction<ClearSearchIntent>(onInvoke: (intent) => clearSearch()),
        },
        child: FocusScope(
          autofocus: true,
          child: KeyboardScaffold(
            focusNode: textNode,
            trackRef: trackRef,
            playingNotifier: ref.read(playingProvider.notifier),
            volumeNotifier: ref.read(volumeProvider.notifier),
            title: buildTitle(argument.title, typeName),
            textStyle: const TextStyle(overflow: TextOverflow.fade, fontSize: 16),
            actions: [
              IconButton(onPressed: openSearchDialog, icon: const Icon(Icons.search), tooltip: i18n(context).com_f3),
              IconButton(
                onPressed: searchTerm.isEmpty ? null : clearSearch,
                icon: const Icon(Icons.clear),
                tooltip: i18n(context).com_ctrl_x,
              ),
              PopupMenuButton(
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<int>(
                      value: 0,
                      child: ListTile(
                        leading: const Icon(Icons.color_lens),
                        title: Text(i18n(context).com_change_theme),
                      ),
                    ),
                    PopupMenuItem<int>(
                      value: 1,
                      child: ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(i18n(context).com_change_language),
                      ),
                    ),
                    PopupMenuItem<int>(
                      enabled: trackRef.artist.isNotEmpty,
                      value: 2,
                      child: ListTile(leading: const Icon(Icons.search), title: Text('Discogs ${trackRef.artist}')),
                    ),
                    PopupMenuItem<int>(
                      enabled: trackRef.artist.isNotEmpty,
                      value: 3,
                      child: ListTile(leading: const Icon(Icons.search), title: Text('Musicbrainz ${trackRef.artist}')),
                    ),
                    PopupMenuItem<int>(
                      enabled: trackRef.artist.isNotEmpty,
                      value: 4,
                      child: ListTile(leading: const Icon(Icons.search), title: Text('Wikipedia ${trackRef.artist}')),
                    ),
                    PopupMenuItem<int>(
                      value: 5,
                      child: ListTile(leading: const Icon(Icons.settings), title: Text(i18n(context).dlg_api_token)),
                    ),
                  ];
                },
                onSelected: (value) {
                  switch (value) {
                    case 0:
                      ThemeProvider.controllerOf(context).nextTheme();
                      break;
                    case 1:
                      if ((Intl.defaultLocale ?? '').contains('de')) {
                        Intl.defaultLocale = 'en';
                        APPLIC().onLocaleChanged(const Locale('en', ''));
                      } else {
                        Intl.defaultLocale = 'de';
                        APPLIC().onLocaleChanged(const Locale('de', ''));
                      }
                      break;
                    case 2:
                      OpenLink.openSite(Website.discogs, trackRef.artist);
                      break;
                    case 3:
                      OpenLink.openSite(Website.musicbrainz, trackRef.artist);
                      break;
                    case 4:
                      OpenLink.openSite(Website.wikipedia, trackRef.artist);
                      break;
                    case 5:
                      Statics.showGeniusTokenDialog(
                        context,
                        i18n(context).dlg_api_token,
                        i18n(context).dlg_api_token_info,
                        prefs.getString(PrefKeys.geniusApiTokenPrefsKey) ?? '',
                      ).then((token) {
                        if (token?.isNotEmpty ?? false) {
                          prefs.setString(PrefKeys.geniusApiTokenPrefsKey, token ?? '');
                          ref.read(playingProvider.notifier).updateGeniusToken(token ?? '');
                        }
                      });
                      break;
                  }
                },
              ),
            ],
            child: Container(
              decoration: ThemeProvider.optionsOf<ThemeOptions>(context).pageDecoration,
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Text(
                    i18n(context).content_selected(
                      selItems.length,
                      argument.content.length,
                      searchTerm.isNotEmpty ? ' - $searchTerm' : '',
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (mq.size.width < landscapeWidth)
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: trackGrid),
                          if (ref.watch(showLyricsProvider))
                            LyricsCard(
                              lyrics: ref.watch(lyricsProvider),
                              height: mq.size.height / 4,
                              width: double.maxFinite,
                            ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: trackGrid),
                          if (ref.watch(showLyricsProvider))
                            LyricsCard(
                              lyrics: ref.watch(lyricsProvider),
                              height: double.maxFinite,
                              width: mq.size.width / 3,
                            ),
                        ],
                      ),
                    ),
                  PlayerWidget(trackRef.title),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  GridView buildTrackGrid(
    double mainAxisExtend,
    List<RawContent> selItems,
    ContentArguments argument,
    String typeName,
    BuildContext context,
  ) {
    return GridView.builder(
      controller: scrollController,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisExtent: mainAxisExtend,
        childAspectRatio: 3,
      ),
      itemBuilder: (ctx, idx) {
        return GestureDetector(
          onTap: () {
            if (selItems[idx].classType != ContentClass.track) {
              if (!searching) {
                setState(() {
                  searching = true;
                  searchIdx = idx;
                });
                // open another page with content
                DlnaService.browseAll(selItems[idx].id).then((value) {
                  if (value.isNotEmpty) {
                    final args = ContentArguments(buildTitle(argument.title, typeName), value);
                    if (context.mounted) {
                      Navigator.of(context).push(Statics.createAnimPageRoute(const ContentPage(), argument: args));
                    }
                  }
                  setState(() {
                    searching = false;
                    searchIdx = -1;
                  });
                });
              }
            } else {
              if ((selItems[idx].trackUrl ?? '').isNotEmpty) {
                if (ref.read(trackProvider).id == selItems[idx].id && ref.read(playingProvider)) {
                  // pause/stop track
                  ref.read(playingProvider.notifier).playPauseTrack();
                } else {
                  // play track
                  if (!ref.read(playlistProvider).contains(selItems[idx])) {
                    Statics.showInfoSnackbar(context, i18n(context).com_new_playlist);
                  }
                  ref.read(trackProvider.notifier).setTrack(selItems[idx]);
                  // make current visible list the playlist and set index
                  ref
                      .read(playlistProvider.notifier)
                      .setPlaylist(selItems.where((element) => element.classType == ContentClass.track).toList());
                  ref.read(playlistIndexProvider.notifier).setIndex(idx);
                  var player = ref.read(playerProvider);
                  player.play(UrlSource(selItems[idx].trackUrl!), mode: PlayerMode.mediaPlayer);
                  ref.read(lruListProvider).add(selItems[idx].id);
                  ref.read(playingProvider.notifier).getLyrics();
                }
              }
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child:
                searching && searchIdx == idx
                    ? ProgressCard(title: selItems[idx].title)
                    : selItems[idx].classType == ContentClass.album
                    ? AlbumCard(container: selItems[idx], disabled: searching)
                    : selItems[idx].classType == ContentClass.track
                    ? TrackCard(track: selItems[idx], disabled: searching)
                    : ContainerCard(container: selItems[idx], disabled: searching),
          ),
        );
      },
      itemCount: selItems.length,
    );
  }
}
