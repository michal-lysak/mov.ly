import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchingBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onFilterPressed;
  final bool initialSelected;
  final ValueChanged<bool>? onSelectedChanged;
  final VoidCallback? onTap; // optional: navigate to search screen

  const SearchingBar({
    super.key,
    required this.controller,
    this.hintText = "Search...",
    required this.onChanged,
    this.onFilterPressed,
    this.initialSelected = false,
    this.onSelectedChanged,
    this.onTap,
  });

  @override
  State<SearchingBar> createState() => _SearchingBarState();
}

class _SearchingBarState extends State<SearchingBar> {
  late FocusNode _focusNode;
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected;
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _selected) {
      setState(() => _selected = hasFocus);
      widget.onSelectedChanged?.call(_selected);
    }
  }

  void _handleTap() {
    // If parent provided an onTap (e.g. navigate to search screen), call it.
    // Also mark as selected so UI updates. We still request focus so focus behavior remains consistent.
    if (widget.onTap != null) {
      widget.onTap!();
    }
    // mark selected
    if (!_selected) {
      setState(() => _selected = true);
      widget.onSelectedChanged?.call(true);
    }
    // Request focus for keyboard (works even if TextField is readOnly in many cases).
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _selected ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : Colors.transparent),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                readOnly: widget.onTap != null, // if parent handles navigation on tap
                onTap: widget.onTap != null ? _handleTap : null,
                onChanged: widget.onChanged,
                style: const TextStyle(color: Colors.white),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: SvgPicture.asset(
                      'lib/assets/icons/search-line.svg',
                      color: Colors.grey,
                      width: 20,
                      height: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
