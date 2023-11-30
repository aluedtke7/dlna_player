import 'package:flutter/material.dart';

import 'package:dlna_player/model/content_container.dart';

class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.topic,
  });

  final ContentContainer topic;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Container(
        width: double.maxFinite,
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              topic.title,
              textScaler: const TextScaler.linear(1.4),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              '${topic.count}',
              textScaler: const TextScaler.linear(1.3),
            ),
          ],
        ),
      ),
    );
  }
}
