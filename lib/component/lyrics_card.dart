import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/statics.dart';
import 'package:dlna_player/model/lyrics.dart';
import 'package:flutter/material.dart';

class LyricsCard extends StatelessWidget {
  const LyricsCard({
    super.key,
    required this.lyrics,
    required this.height,
  });

  final Lyrics lyrics;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: Statics.tintColor(Theme.of(context).cardColor, 0.9),
      child: Container(
        width: double.maxFinite,
        height: height,
        margin: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                lyrics.state == LyricsState.success
                    ? lyrics.lyrics
                    : i18n(context).lyrics_state(lyrics.state.toString()),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
