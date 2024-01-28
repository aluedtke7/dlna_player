import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/statics.dart';
import 'package:dlna_player/model/lyrics.dart';
import 'package:flutter/material.dart';

class LyricsCard extends StatelessWidget {
  const LyricsCard({
    super.key,
    required this.lyrics,
    required this.height,
    required this.width,
  });

  final Lyrics lyrics;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: Statics.tintColor(Theme.of(context).cardColor, 0.9),
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(8),
        child: (lyrics.state == LyricsState.success)
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      lyrics.lyrics,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 500,
                    ),
                  ],
                ),
              )
            : Center(
                // heightFactor: 10,
                child: Text(
                  i18n(context).lyrics_state(lyrics.state.toString()),
                  textScaler: const TextScaler.linear(1.3),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ),
    );
  }
}
