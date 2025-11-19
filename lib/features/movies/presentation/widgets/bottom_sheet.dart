import 'package:flutter/material.dart';
import 'package:movly/features/movies/data/cache/backdrop_cache.dart';

import '../../data/models/movie.dart';

class MovieSheet extends StatefulWidget {
  final Movie movie;
  const MovieSheet({
    super.key,
    required this.movie,
  });

  @override
  State<MovieSheet> createState() => _MovieSheetState();
}

class _MovieSheetState extends State<MovieSheet> {
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backdrops = widget.movie.backdropPath;

    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: PageView.builder(
              itemCount: backdrops?.length,
              onPageChanged: (index) => _currentIndex.value = index,
                itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  child: CachedBackdropImage.fromMovie(widget.movie),
                );
                },
            )
          )
        ],
      ),
    );
  }
}
