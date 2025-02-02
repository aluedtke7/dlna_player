import 'package:flutter/cupertino.dart';

class ArtistTitleFader extends StatelessWidget {
  final String artist;
  final String title;
  final bool showArtist;

  const ArtistTitleFader({
    super.key,
    required this.artist,
    required this.title,
    required this.showArtist,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return AnimatedCrossFade(
      firstChild: SizedBox(
        width: mq.size.width - 110,
        child: Text(
          title,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
      secondChild: SizedBox(
        width: mq.size.width - 110,
        child: Text(
          artist,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
      crossFadeState: showArtist ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 500),
      sizeCurve: Curves.bounceInOut,
    );
  }
}
