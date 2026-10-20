import 'package:dlna_player/component/tile_style.dart';
import 'package:flutter/material.dart';
import 'package:upnp2/upnp.dart' show Device;

class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key, required this.device, this.onTap});

  final Device device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Uri location = Uri.parse(device.urlBase ?? '');
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StyledTile(
      onTap: onTap,
      child: Row(
        children: [
          const IconBadge(icon: Icons.dns_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.friendlyName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(location.origin, style: textTheme.bodySmall!.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
