import 'package:flutter/material.dart';

class HorizontalScrolling_Categories extends StatefulWidget {
  const HorizontalScrolling_Categories({super.key});

  @override
  State<HorizontalScrolling_Categories> createState() => _HorizontalScrolling_CategoriesState();
}

class _HorizontalScrolling_CategoriesState extends State<HorizontalScrolling_Categories> {
  // Added some example categories for display purposes
  List<String> categories = ["Action", "Comedy", "Drama", "Horror", "Sci-Fi"];

  @override
  Widget build(BuildContext context) {
    // Using SizedBox to give the horizontal list a defined height.
    // ListView.builder in a horizontal direction needs a constrained height.
    return SizedBox(
      height: 50, // Example height, adjust as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Chip(
              label: Text(categories[index]),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.transparent,
            ),
          );
        },
      ),
    );
  }
}
