import 'package:flutter/material.dart';
import 'package:upnp2/upnp.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
  });
  final Device device;

  @override
  Widget build(BuildContext context) {
    final Uri location = Uri.parse(device.urlBase ?? '');

    return Card(
      elevation: 5,
      child: Container(
        width: double.maxFinite,
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              device.friendlyName ?? '',
              textScaleFactor: 1.5,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              location.origin,
              textScaleFactor: 1.2,
            ),
          ],
        ),
      ),
    );
  }
}
