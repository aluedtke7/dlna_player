import 'dart:async';

import 'package:dlna_player/application.dart';
import 'package:dlna_player/component/card/album_card.dart';
import 'package:dlna_player/component/card/container_card.dart';
import 'package:dlna_player/component/card/lyrics_card.dart';
import 'package:dlna_player/component/card/progress_card.dart';
import 'package:dlna_player/component/card/track_card.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/app_scaffold.dart';
import 'package:dlna_player/component/player_widget.dart';
import 'package:dlna_player/component/dialog.dart';
import 'package:dlna_player/component/find_bar.dart';
import 'package:dlna_player/component/snackbar.dart';
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

class OpenFindIntent extends Intent {
  const OpenFindIntent();
}

class _ContentPageState extends ConsumerState<ContentPage> {
  var searchTerm = '';
  var currentTrackTitle = '';
  var showPlayerWidget = true;
  var searching = false;
  var searchIdx = -1;
  var lastIdx = -1;
  var lastInfoString = '';
  var gridWidth = 0.0;
  late SharedPreferences prefs;
  final textNode = FocusNode();
  final maxCrossAxisExtent = 400.0;
  final landscapeWidth = 600;
  late ScrollController scrollController;
  var findActive = false;
  var findPos = -1;
  List<int> findHits = const [];
  final findController = TextEditingController();
  static const findDebounce = Duration(milliseconds: 750);
  Timer? findDebounceTimer;

  /// The search term the hits are computed from, set [findDebounce] after typing stops.
  var findTerm = '';
  final findFocus = FocusNode();

  /// Gets the focus back when the find bar closes, so the page shortcuts keep working.
  final pageFocus = FocusNode();
  FocusNode? focusBeforeFind;
  var isAlbumGrid = false;
  var gridMainAxisExtent = 0.0;

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
    findController.dispose();
    findDebounceTimer?.cancel();
    findFocus.dispose();
    pageFocus.dispose();
    super.dispose();
  }

  double gridPadding(bool wide) => wide ? 30 : 8;

  SliverGridDelegateWithMaxCrossAxisExtent gridDelegate(bool wide) => isAlbumGrid
      ? SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 0.7,
          crossAxisSpacing: wide ? 20 : 12,
          mainAxisSpacing: wide ? 24 : 16,
        )
      : SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          mainAxisExtent: gridMainAxisExtent,
          crossAxisSpacing: 12,
          mainAxisSpacing: 4,
        );

  void openFind() {
    if (!findActive) focusBeforeFind = FocusManager.instance.primaryFocus;
    setState(() => findActive = true);
    findFocus.requestFocus();
  }

  void closeFind() {
    findDebounceTimer?.cancel();
    setState(() {
      findActive = false;
      findPos = -1;
      findTerm = '';
      findController.clear();
    });
    // Otherwise the focus falls back to the route's scope, which is above the page shortcuts.
    final previous = focusBeforeFind;
    if (previous != null && previous is! FocusScopeNode && previous.context != null) {
      previous.requestFocus();
    } else {
      pageFocus.requestFocus();
    }
  }

  void onFindChanged(String _) {
    findDebounceTimer?.cancel();
    findDebounceTimer = Timer(findDebounce, applyFindTerm);
  }

  /// Uses the typed text as search term and scrolls to its first hit.
  void applyFindTerm() {
    findDebounceTimer?.cancel();
    if (!mounted) return;
    setState(() {
      findTerm = findController.text;
      findPos = -1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToFindHit());
  }

  /// Moves to the hit [delta] steps away (wrapping around) and scrolls to it.
  void moveFind(int delta) {
    // Moving while the debounce is pending searches right away.
    if (findDebounceTimer?.isActive ?? false) {
      applyFindTerm();
      return;
    }
    if (findHits.isEmpty) return;
    setState(() => findPos = (findPos + delta) % findHits.length);
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToFindHit());
  }

  /// Plays the track or opens the container of the current hit.
  void activateFindHit(List<RawContent> selItems, ContentArguments argument, String typeName) {
    if (findPos < 0 || findPos >= findHits.length) return;
    openOrPlay(selItems, findHits[findPos], argument, typeName);
  }

  void submitFind(List<RawContent> selItems, ContentArguments argument, String typeName) {
    // Enter while the debounce is pending searches right away and uses the first hit.
    if (findDebounceTimer?.isActive ?? false) {
      applyFindTerm();
      WidgetsBinding.instance.addPostFrameCallback((_) => activateFindHit(selItems, argument, typeName));
      return;
    }
    activateFindHit(selItems, argument, typeName);
  }

  void scrollToFindHit() {
    if (findPos >= 0 && findPos < findHits.length) scrollToIndex(findHits[findPos]);
  }

  /// Scrolls the grid so the row with the tile at [index] is fully visible.
  void scrollToIndex(int index) {
    if (!mounted || !scrollController.hasClients) return;
    final wide = MediaQuery.sizeOf(context).width >= landscapeWidth;
    final delegate = gridDelegate(wide);
    final crossAxisExtent = gridWidth - 2 * gridPadding(wide);
    final position = scrollController.position;
    final rowTop = gridRowOffset(delegate, index, crossAxisExtent);
    final rowBottom = rowTop + gridRowExtent(delegate, crossAxisExtent);
    if (rowTop >= position.pixels && rowBottom <= position.pixels + position.viewportDimension) return;
    final target = rowTop.clamp(0.0, position.maxScrollExtent);
    // The lazy grid can't build fast enough for long animated jumps.
    if ((target - position.pixels).abs() > position.viewportDimension * 2) {
      scrollController.jumpTo(target);
    } else {
      scrollController.animateTo(target, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
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
                .where((el) => el.title.toLowerCase().contains(searchTerm) || el.artist.toLowerCase().contains(searchTerm))
                .toList();
        mainAxisExtend = 76;
        break;
      case ContentClass.artist:
        selItems =
            argument.content
                .where((el) => el.title.toLowerCase().contains(searchTerm) || el.genre.toLowerCase().contains(searchTerm))
                .toList();
        mainAxisExtend = 76;
        break;
      case ContentClass.genre:
      case ContentClass.playlist:
        selItems = argument.content.where((el) => el.title.toLowerCase().contains(searchTerm)).toList();
        mainAxisExtend = 76;
        break;
      case ContentClass.folder:
        selItems = argument.content.where((el) => el.title.toLowerCase().contains(searchTerm)).toList();
        mainAxisExtend = 76;
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
        mainAxisExtend = 72;
        break;
      default:
        selItems = argument.content;
        mainAxisExtend = 76;
    }
    isAlbumGrid = type == ContentClass.album;
    gridMainAxisExtent = mainAxisExtend;
    findHits = findActive ? findMatches(selItems, findTerm) : const [];
    if (findPos >= findHits.length || (findPos < 0 && findHits.isNotEmpty)) {
      findPos = findHits.isEmpty ? -1 : 0;
    }
    final trackGrid = buildTrackGrid(selItems, argument, typeName, context);

    // The ScrollController must be connected to the UI in order to work and the length of the play list
    // must be the same as the list being displayed. This is not totally correct, but it will avoid scroll events when
    // the two lists don't match in length.
    if (scrollController.hasClients && selItems.length == playListRef.length && type == ContentClass.track) {
      // Only scroll when the playing track has changed
      if (lastIdx != playListIndexRef) {
        lastIdx = playListIndexRef;
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToIndex(playListIndexRef));
      }
    }

    void openSearchDialog() {
      DialogHelper.showSearchDialog(context, i18n(context).content_search_for, searchTerm).then((value) {
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
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyG): const OpenFindIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          OpenSearchIntent: CallbackAction<OpenSearchIntent>(onInvoke: (intent) => openSearchDialog()),
          ClearSearchIntent: CallbackAction<ClearSearchIntent>(onInvoke: (intent) => clearSearch()),
          OpenFindIntent: CallbackAction<OpenFindIntent>(onInvoke: (intent) => openFind()),
        },
        child: Focus(
          focusNode: pageFocus,
          child: AppScaffold(
            title: typeName,
            breadcrumb: argument.title.replaceAll(' - ', ' / '),
            actions: [
                if (mq.size.width >= landscapeWidth) ...[
                  Tooltip(
                    message: i18n(context).com_ctrl_g,
                    child: OutlinedButton.icon(
                      onPressed: openFind,
                      icon: const Icon(Icons.search),
                      label: Text(i18n(context).content_search),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: i18n(context).com_f3,
                    child: OutlinedButton.icon(
                      onPressed: openSearchDialog,
                      icon: const Icon(Icons.filter_list),
                      label: Text(searchTerm.isEmpty ? i18n(context).content_filter : searchTerm),
                    ),
                  ),
                ] else ...[
                  IconButton(onPressed: openFind, icon: const Icon(Icons.search), tooltip: i18n(context).com_ctrl_g),
                  IconButton(onPressed: openSearchDialog, icon: const Icon(Icons.filter_list), tooltip: i18n(context).com_f3),
                ],
                IconButton(
                  onPressed: searchTerm.isEmpty ? null : clearSearch,
                  icon: const Icon(Icons.filter_list_off),
                  tooltip: i18n(context).com_ctrl_x,
                ),
                PopupMenuButton(
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<int>(
                        value: 0,
                        child: ListTile(leading: const Icon(Icons.color_lens), title: Text(i18n(context).com_change_theme)),
                      ),
                      PopupMenuItem<int>(
                        value: 1,
                        child: ListTile(leading: const Icon(Icons.language), title: Text(i18n(context).com_change_language)),
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
                        DialogHelper.showGeniusTokenDialog(
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
              //height: mq.size.height-130,
              child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(mq.size.width >= landscapeWidth ? 40 : 16, 4, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          i18n(context).content_selected(selItems.length, argument.content.length, searchTerm.isNotEmpty ? ' - $searchTerm' : ''),
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    if (findActive)
                      Padding(
                        padding: EdgeInsets.fromLTRB(mq.size.width >= landscapeWidth ? 30 : 8, 0, 8, 8),
                        child: FindBar(
                          controller: findController,
                          focusNode: findFocus,
                          term: findTerm,
                          hitPosition: findPos,
                          hitCount: findHits.length,
                          onChanged: onFindChanged,
                          onNext: () => moveFind(1),
                          onPrevious: () => moveFind(-1),
                          onSubmit: () => submitFind(selItems, argument, typeName),
                          onClose: closeFind,
                        ),
                      ),
                    if (mq.size.width < landscapeWidth)
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: trackGrid),
                            if (ref.watch(showLyricsProvider))
                              LyricsCard(lyrics: ref.watch(lyricsProvider), height: mq.size.height / 4, width: double.maxFinite),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: trackGrid),
                            if (ref.watch(showLyricsProvider))
                              LyricsCard(lyrics: ref.watch(lyricsProvider), height: double.maxFinite, width: mq.size.width / 3),
                          ],
                        ),
                      ),
                    PlayerWidget(trackRef.title),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  /// Opens the container or plays the track at [idx], like tapping its tile.
  Future<void> openOrPlay(List<RawContent> selItems, int idx, ContentArguments argument, String typeName) async {
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
            if (mounted) {
              Navigator.of(context).push(DialogHelper.createAnimPageRoute(const ContentPage(), argument: args));
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
        if (ref.read(trackProvider).id == selItems[idx].id) {
          // current track: toggle play/pause (resume from current position)
          ref.read(playingProvider.notifier).playPauseTrack();
        } else {
          // play track
          final currentPlaylist = ref.read(playlistProvider);
          final isInCurrentPlaylist = currentPlaylist.any((track) => track.id == selItems[idx].id);
          if (!isInCurrentPlaylist) {
            SnackbarHelper.showInfoSnackbar(context, i18n(context).com_new_playlist);
          }
          ref.read(trackProvider.notifier).setTrack(selItems[idx]);
          // make current visible list the playlist and set index
          await ref
              .read(playlistProvider.notifier)
              .setPlaylist(selItems.where((element) => element.classType == ContentClass.track).toList(), initialIndex: idx);
          ref.read(playlistIndexProvider.notifier).setIndex(idx);
          ref.read(playingProvider.notifier).getLyrics();
        }
      }
    }
  }

  LayoutBuilder buildTrackGrid(
    List<RawContent> selItems,
    ContentArguments argument,
    String typeName,
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        gridWidth = constraints.maxWidth;
        final wide = MediaQuery.sizeOf(context).width >= landscapeWidth;
        final trackRef = ref.watch(trackProvider);
        return GridView.builder(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(gridPadding(wide), 0, gridPadding(wide), 16),
          gridDelegate: gridDelegate(wide),
          itemBuilder: (ctx, idx) {
            final staggerIdx = idx.clamp(0, 14);
            final totalDur = 360 + staggerIdx * 35;
            final startRatio = (staggerIdx * 35) / totalDur;
            final isFindHit = findPos >= 0 && findPos < findHits.length && findHits[findPos] == idx;
            Future<void> handleTap() => openOrPlay(selItems, idx, argument, typeName);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: totalDur),
              curve: Interval(startRatio, 1.0, curve: Curves.easeOutCubic),
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(offset: Offset(0, (1 - t) * 6), child: child),
              ),
              child: GestureDetector(
                onTap: handleTap,
                child: Container(
                  foregroundDecoration: isFindHit
                      ? BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.5),
                          borderRadius: BorderRadius.circular(18),
                        )
                      : null,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    // Fill the grid cell so all tiles get the same size.
                    layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
                    child:
                        searching && searchIdx == idx
                            ? ProgressCard(title: selItems[idx].title)
                            : selItems[idx].classType == ContentClass.album
                            ? AlbumCard(
                                container: selItems[idx],
                                disabled: searching,
                                isPlaying: trackRef.album.isNotEmpty && trackRef.album == selItems[idx].title,
                              )
                            : selItems[idx].classType == ContentClass.track
                            ? TrackCard(track: selItems[idx], disabled: searching, onTap: handleTap)
                            : ContainerCard(container: selItems[idx], disabled: searching),
                  ),
                ),
              ),
            );
          },
          itemCount: selItems.length,
        );
      },
    );
  }
}
