import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.drawer,
    this.actions,
    this.textStyle,
  });

  final String title;
  final Widget? drawer;
  final Widget child;
  final List<Widget>? actions;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        titleTextStyle: textStyle,
        actions: actions,
      ),
      drawer: drawer,
      body: SafeArea(child: child),
    );
  }
}
