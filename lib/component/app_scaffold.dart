import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.title, required this.child, this.drawer, this.actions, this.breadcrumb, this.subtitle});

  final String title;
  final Widget? drawer;
  final Widget child;
  final List<Widget>? actions;

  /// Small muted line above the title, e.g. the parent containers.
  final String? breadcrumb;

  /// Small muted line below the title, e.g. the server address.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final captionStyle = textTheme.bodySmall!.copyWith(color: cs.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (breadcrumb?.isNotEmpty ?? false) Text(breadcrumb!, style: captionStyle, overflow: TextOverflow.ellipsis),
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
            ),
            if (subtitle?.isNotEmpty ?? false) Text(subtitle!, style: captionStyle, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: actions,
      ),
      drawer: drawer,
      body: SafeArea(child: child),
    );
  }
}
