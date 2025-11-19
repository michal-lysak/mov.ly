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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SvgPicture.asset(
                    'lib/assets/icons/search-line.svg',
                    color: Colors.grey,
                    width: 20,
                    height: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 25,
                  minHeight: 25,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Filter button
        InkWell(
          onTap: onFilterPressed,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: SvgPicture.asset(
              'lib/assets/icons/filter-line.svg',
              color: Colors.white,
              width: 20,
              height: 20,
            ),
          ),
        ),
      ],
    );
  }
}
