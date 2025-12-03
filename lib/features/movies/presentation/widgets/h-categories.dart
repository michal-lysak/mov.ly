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
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _displayCategories = List.from(_initialCategories);
  }

  void _onCategoryTapped(String category) {
    setState(() {
      if (_selectedCategory == category) {
        // Deselect
        _selectedCategory = null;
        _displayCategories = List.from(_initialCategories)..sort();
        // Notify parent: null means "show default/trending"
        widget.onCategoryChanged(null);
      } else {
        // Select
        _selectedCategory = category;
        _displayCategories = List.from(_initialCategories);
        _displayCategories.remove(category);
        _displayCategories.insert(0, category);
        // Notify parent
        widget.onCategoryChanged(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35, // Slightly increased to fit borders nicely
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _displayCategories.length,
        itemBuilder: (context, index) {
          final category = _displayCategories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _onCategoryTapped(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.grey.shade300.withOpacity(0.3),
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
                    child: Text(category),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}