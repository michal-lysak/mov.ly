import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HorizontalScrolling_Categories extends StatefulWidget {
  // Callback to send data to parent
  final Function(String?) onCategoryChanged;

  const HorizontalScrolling_Categories({
    super.key,
    required this.onCategoryChanged
  });

  @override
  State<HorizontalScrolling_Categories> createState() => _HorizontalScrolling_CategoriesState();
}

class _HorizontalScrolling_CategoriesState extends State<HorizontalScrolling_Categories> {
  // Added "Trending" as a default state option if you want it
  final List<String> _initialCategories = const ["Action", "Adventure", "Animation", "Comedy", "Crime", "Documentary",
    "Drama", "Family", "Fantasy", "History", "Horror", "Music", "Mystery",
    "Romance", "Sci-Fi", "TV Movie", "Thriller", "War", "Western"];
  late List<String> _displayCategories;
  final _listKey = GlobalKey<AnimatedListState>();
  final _scrollController = ScrollController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _displayCategories = List.from(_initialCategories)..sort();
  }

  void _onCategoryTapped(String category) {
    if (_selectedCategory == category) {
      // --- DESELECT ---
      final int oldIndex = _displayCategories.indexOf(category);
      final removedItem = _displayCategories.removeAt(oldIndex);
      _listKey.currentState?.removeItem(
        oldIndex,
            (context, animation) => _buildCategoryItem(removedItem, false, animation),
      );

      _displayCategories = List.from(_initialCategories)..sort();
      final int newIndex = _displayCategories.indexOf(removedItem);
      _listKey.currentState?.insertItem(newIndex);

      setState(() => _selectedCategory = null);
      widget.onCategoryChanged(null);

    } else {
      // --- SELECT ---
      final int oldIndex = _displayCategories.indexOf(category);
      final removedItem = _displayCategories.removeAt(oldIndex);
      _listKey.currentState?.removeItem(
        oldIndex,
            (context, animation) => _buildCategoryItem(removedItem, false, animation),
      );

      _displayCategories.insert(0, removedItem);
      _listKey.currentState?.insertItem(0);

      setState(() => _selectedCategory = category);
      widget.onCategoryChanged(category);

      // Scroll to the beginning
      _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35, // Slightly increased to fit borders nicely
      child: AnimatedList(
        key: _listKey,
        controller: _scrollController,
        padding: const EdgeInsets.only(left: 15, right: 9), // Add padding to the start of the list
        scrollDirection: Axis.horizontal,
        initialItemCount: _displayCategories.length,
        itemBuilder: (context, index, animation) {
          final category = _displayCategories[index];
          final isSelected = category == _selectedCategory;
          return _buildCategoryItem(
            category,
            isSelected,
            animation,
            onTap: () => _onCategoryTapped(category),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(String category, bool isSelected, Animation<double> animation, {VoidCallback? onTap}) {
    return SizeTransition(
      sizeFactor: animation,
      axis: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: GoogleFonts.afacad(
                  fontSize: 16,
                  color: isSelected ? Colors.black : Colors.white,
                ),
                child: Text(category, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}