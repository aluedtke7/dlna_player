import 'package:dlna_player/component/extensions.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:flutter/material.dart';

class AnimatedVolume extends StatelessWidget {
  final bool show;
  final double volume;

  const AnimatedVolume({
    super.key,
    required this.show,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: Duration(milliseconds: 500),
      child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade600,
                spreadRadius: 1,
                blurRadius: 15,
                blurStyle: BlurStyle.outer,
              )
            ],
          ),
          child: Text(
            i18n(context).player_volume(volume.showPercent()),
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          )),
    );
  }
}
