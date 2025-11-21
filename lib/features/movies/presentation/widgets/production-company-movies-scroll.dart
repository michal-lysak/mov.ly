import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CompanyMoviesSection extends StatefulWidget {
  final int movieId;
  final List<dynamic> productionCompanies;

  const CompanyMoviesSection({
    super.key,
    required this.movieId,
    required this.productionCompanies,
  });

  @override
  State<CompanyMoviesSection> createState() => _CompanyMoviesSectionState();
}

class _CompanyMoviesSectionState extends State<CompanyMoviesSection> {
  List<dynamic> _companyMovies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyMovies();
  }

  Future<void> _loadCompanyMovies() async {
    if (widget.productionCompanies.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final companyId = widget.productionCompanies.first['id'];
    final apiKey = dotenv.env['TMDB_API_KEY'];
    final url =
        "https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_companies=$companyId";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      setState(() {
        _companyMovies = jsonData["results"];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_companyMovies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),

        GridView.builder(
            padding: const EdgeInsets.all(17),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _companyMovies.length,
            itemBuilder: (context, index) {
              final movie = _companyMovies[index];
              final poster = movie["poster_path"];

              return GestureDetector(
                onTap: () {
                  // Your existing navigation to movie detail goes here
                  // Example:
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (_) => MovieDetailPage(movieId: movie["id"]),
                  // ));
                },
                child: Container(
                  width: 30,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: poster != null
                        ? Image.network(
                      "https://image.tmdb.org/t/p/w500$poster",
                      fit: BoxFit.cover,
                    )
                        : Container(
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: Text("No image"),
                      ),
                    ),
                  ),
                ),
              );
            },
        ),
      ],
    );
  }
}
