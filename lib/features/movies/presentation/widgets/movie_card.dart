import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.year,
    required this.category,
  });

  final String title;
  final String posterUrl;
  final int year;
  final String category;

  @override
  Widget build(BuildContext context) {
    // possible TODO: use of gesturedetector
    return Container(
      width: 312,
      height: 194,
      child: Column(

        children: [

        ],
      ),
    );
  }
}
