import 'package:dlna_player/component/tile_style.dart';
import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return StyledTile(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
          const LinearProgressIndicator(borderRadius: BorderRadius.all(Radius.circular(2))),
        ],
      ),
    );
  }
}
