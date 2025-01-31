import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardScaffold extends StatelessWidget {
  const KeyboardScaffold({
    super.key,
    required this.focusNode,
    required this.trackRef,
    required this.playingNotifier,
    required this.volumeNotifier,
    required this.title,
    required this.child,
    this.drawer,
    this.actions,
    this.textStyle,
  });

  final FocusNode focusNode;
  final RawContent trackRef;
  final PlayingNotifier playingNotifier;
  final VolumeNotifier volumeNotifier;
  final String title;
  final Widget? drawer;
  final Widget child;
  final List<Widget>? actions;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
        autofocus: true,
        focusNode: focusNode,
        onKeyEvent: (k) {
          if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.space)) {
            if (trackRef.title.isNotEmpty) {
              playingNotifier.playPauseTrack();
            }
          }
          if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowUp)) {
            volumeNotifier.increaseVolume();
          }
          if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowDown)) {
            volumeNotifier.decreaseVolume();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: Text(
              title,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            titleTextStyle: textStyle,
            actions: actions,
          ),
          drawer: drawer,
          body: child,
        ));
  }
}
