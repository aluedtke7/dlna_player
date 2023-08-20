import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    Key? key,
    required this.title,
  }) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Container(
        height: double.maxFinite,
        margin: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(title),
              const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
