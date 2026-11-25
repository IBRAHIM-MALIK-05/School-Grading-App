// lib/widgets/search_picker.dart
// Searchable pickers used by the Admin forms instead of long dropdowns:
//  - showSearchPicker      : pick ONE item (e.g. a Class Teacher, a subject)
//  - showMultiSearchPicker : tick SEVERAL items (e.g. classes for a subject)
//  - PickerField           : a form field that shows the choice and opens a picker
//  - SearchBox             : the search bar at the top of the Admin lists
// The list filters while you type, so 30+ subjects or classes are never a problem.

import 'package:flutter/material.dart';

import 'app_theme.dart';

class PickerItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final bool enabled; // false = shown greyed out, cannot be picked
  final IconData? icon;

  const PickerItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.enabled = true,
    this.icon,
  });

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty ||
        title.toLowerCase().contains(q) ||
        (subtitle?.toLowerCase().contains(q) ?? false);
  }
}

// Pick ONE item. Returns the chosen item, or null if the sheet was closed.
Future<PickerItem<T>?> showSearchPicker<T>(
  BuildContext context, {
  required String title,
  required List<PickerItem<T>> items,
  T? selected,
  String searchHint = 'Search...',
}) {
  return showModalBottomSheet<PickerItem<T>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PickerSheet<T>(
      title: title,
      items: items,
      searchHint: searchHint,
      initial: {?selected},
      multi: false,
    ),
  );
}

// Tick SEVERAL items. Returns the ticked values, or null if the sheet was closed.
Future<Set<T>?> showMultiSearchPicker<T>(
  BuildContext context, {
  required String title,
  required List<PickerItem<T>> items,
  Set<T> selected = const {},
  String searchHint = 'Search...',
}) {
  return showModalBottomSheet<Set<T>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PickerSheet<T>(
      title: title,
      items: items,
      searchHint: searchHint,
      initial: selected,
      multi: true,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  final String title;
  final List<PickerItem<T>> items;
  final String searchHint;
  final Set<T> initial;
  final bool multi;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.searchHint,
    required this.initial,
    required this.multi,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';
  late final Set<T> _ticked = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final visible = widget.items.where((i) => i.matches(_query)).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBox(
                hint: widget.searchHint,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: Text('Nothing matches your search.',
                          style: TextStyle(color: AppColors.muted)))
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) => _tile(visible[i]),
                    ),
            ),
            if (widget.multi)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _ticked),
                    icon: const Icon(Icons.check),
                    label: Text('Done (${_ticked.length} selected)'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(PickerItem<T> item) {
    final subtitle = item.subtitle == null ? null : Text(item.subtitle!);
    if (widget.multi) {
      return CheckboxListTile(
        value: _ticked.contains(item.value),
        enabled: item.enabled,
        title: Text(item.title),
        subtitle: subtitle,
        secondary: item.icon == null ? null : Icon(item.icon),
        onChanged: (v) => setState(() {
          if (v == true) {
            _ticked.add(item.value);
          } else {
            _ticked.remove(item.value);
          }
        }),
      );
    }
    final isSelected = _ticked.contains(item.value);
    return ListTile(
      enabled: item.enabled,
      leading: item.icon == null ? null : Icon(item.icon),
      title: Text(item.title,
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: subtitle,
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () => Navigator.pop(context, item),
    );
  }
}

// A form field that looks like a text box; tapping it opens a picker.
class PickerField extends StatelessWidget {
  final String label;
  final String valueText;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isEmpty; // shows the value in grey (nothing chosen yet)
  final String? errorText;

  const PickerField({
    super.key,
    required this.label,
    required this.valueText,
    required this.icon,
    required this.onTap,
    this.isEmpty = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    // One accessible button ("Class Teacher of: Class 9 - C") that screen readers can also tap
    return Semantics(
      container: true, // its own node - do not merge into the surrounding card
      button: true,
      enabled: onTap != null,
      label: errorText == null ? '$label: $valueText' : '$label: $valueText. $errorText',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(Icons.search),
            errorText: errorText,
            enabled: onTap != null,
          ),
          child: Text(
            valueText,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isEmpty ? AppColors.muted : null),
          ),
        ),
      ),
    );
  }
}

// Search bar at the top of the Admin lists (Users, Classes, Subjects)
class SearchBox extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const SearchBox({super.key, required this.hint, required this.onChanged, this.autofocus = false});

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: (v) {
        setState(() {}); // show / hide the clear button
        widget.onChanged(v);
      },
      decoration: InputDecoration(
        labelText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear search',
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  widget.onChanged('');
                },
              ),
      ),
    );
  }
}
