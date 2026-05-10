import 'dart:async';

import 'package:dlna_player/component/i18n_util.dart';
import 'package:flutter/material.dart';

class DialogHelper {
  static Future<String?> showSearchDialog(BuildContext context, String title, String initValue) async {
    return showDialog<String?>(
      context: context,
      builder: (ctx) => _SearchDialog(title: title, initValue: initValue),
    );
  }

  static Future<String?> showGeniusTokenDialog(BuildContext context, String title, String info, String initVal) async {
    return showDialog<String?>(
      context: context,
      builder: (ctx) => _GeniusTokenDialog(title: title, info: info, initVal: initVal),
    );
  }

  static Route createAnimPageRoute(Widget page, {String? name, Object? argument, bool toRight = false}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = toRight ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnim = animation.drive(tween);
        return SlideTransition(
          position: offsetAnim,
          child: child,
        );
      },
      settings: RouteSettings(arguments: argument, name: name),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({required this.title, required this.initValue});

  final String title;
  final String initValue;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initValue);
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.initValue.length);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: i18n(context).com_search,
          suffixIcon: IconButton(
            onPressed: () => _controller.clear(),
            icon: const Icon(Icons.clear),
          ),
        ),
        keyboardType: TextInputType.text,
        onEditingComplete: () => Navigator.of(context).pop(_controller.text),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(i18n(context).com_cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(i18n(context).com_ok),
        ),
      ],
    );
  }
}

class _GeniusTokenDialog extends StatefulWidget {
  const _GeniusTokenDialog({required this.title, required this.info, required this.initVal});

  final String title;
  final String info;
  final String initVal;

  @override
  State<_GeniusTokenDialog> createState() => _GeniusTokenDialogState();
}

class _GeniusTokenDialogState extends State<_GeniusTokenDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initVal);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.info),
            const SizedBox(height: 16),
            TextFormField(
              autofocus: true,
              controller: _controller,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: i18n(context).dlg_api_token_label),
              keyboardType: TextInputType.text,
              onFieldSubmitted: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(i18n(context).com_cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(i18n(context).com_save),
        ),
      ],
    );
  }
}
