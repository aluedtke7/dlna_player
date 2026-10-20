import 'dart:math';

import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Indices of the [items] whose title, artist or album contains [term] (case insensitive).
List<int> findMatches(List<RawContent> items, String term) {
  final t = term.trim().toLowerCase();
  if (t.isEmpty) return const [];
  return [
    for (var i = 0; i < items.length; i++)
      if (items[i].title.toLowerCase().contains(t) ||
          items[i].artist.toLowerCase().contains(t) ||
          items[i].album.toLowerCase().contains(t))
        i,
  ];
}

/// Number of columns of a grid laid out by [delegate] within [crossAxisExtent]
/// (the grid width without its padding).
int gridColumns(SliverGridDelegateWithMaxCrossAxisExtent delegate, double crossAxisExtent) =>
    max(1, (crossAxisExtent / (delegate.maxCrossAxisExtent + delegate.crossAxisSpacing)).ceil());

/// Height of one grid row without the spacing to the next row.
double gridRowExtent(SliverGridDelegateWithMaxCrossAxisExtent delegate, double crossAxisExtent) {
  final columns = gridColumns(delegate, crossAxisExtent);
  final childCrossAxisExtent = max(0.0, crossAxisExtent - delegate.crossAxisSpacing * (columns - 1)) / columns;
  return delegate.mainAxisExtent ?? childCrossAxisExtent / delegate.childAspectRatio;
}

/// Scroll offset of the row holding [index].
double gridRowOffset(SliverGridDelegateWithMaxCrossAxisExtent delegate, int index, double crossAxisExtent) =>
    (index ~/ gridColumns(delegate, crossAxisExtent)) * (gridRowExtent(delegate, crossAxisExtent) + delegate.mainAxisSpacing);

/// Search field with hit counter and buttons to jump between the hits.
class FindBar extends StatelessWidget {
  const FindBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.term,
    required this.hitPosition,
    required this.hitCount,
    required this.onChanged,
    required this.onNext,
    required this.onPrevious,
    required this.onSubmit,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// The term the hits were searched for (may lag behind the typed text).
  final String term;

  /// Zero based position of the current hit, -1 when there is none.
  final int hitPosition;
  final int hitCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  /// Called on Enter, plays or opens the current hit.
  final VoidCallback onSubmit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = term.trim().isEmpty
        ? ''
        : hitCount == 0
        ? i18n(context).content_find_none
        : '${hitPosition + 1} / $hitCount';
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): onNext,
        const SingleActivator(LogicalKeyboardKey.arrowUp): onPrevious,
        const SingleActivator(LogicalKeyboardKey.escape): onClose,
      },
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: i18n(context).com_search,
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
              ),
              onChanged: onChanged,
              onSubmitted: (_) {
                onSubmit();
                focusNode.requestFocus();
              },
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: cs.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            onPressed: hitCount > 0 ? onPrevious : null,
            icon: const Icon(Icons.keyboard_arrow_up),
            tooltip: i18n(context).content_find_previous,
          ),
          IconButton(
            onPressed: hitCount > 0 ? onNext : null,
            icon: const Icon(Icons.keyboard_arrow_down),
            tooltip: i18n(context).content_find_next,
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close), tooltip: i18n(context).content_find_close),
        ],
      ),
    );
  }
}
