import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchingBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onFilterPressed; // callback for filter button

  const SearchingBar({
    super.key,
    required this.controller,
    this.hintText = "Search...",
    required this.onChanged,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search bar
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),

              textAlignVertical: TextAlignVertical.center, // centers baseline

              decoration: InputDecoration(
                hintText: hintText,
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

                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),

                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),

          ),
        ),
      ],
    );
  }
}
