import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title:  Text(
          'Mov.ly',
        style: GoogleFonts.lilyScriptOne(
          fontSize: 32,
          fontWeight: FontWeight.normal,
        ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                // TODO: Navigate to profile/settings
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Section For you
                //TODO: For you page made by algorithm
              Text(
              'For you',
              style: GoogleFonts.afacad(
                  fontSize: 24,
                  //fontWeight: FontWeight.bold
              ),
            ),
                SizedBox(height: 16),

                SizedBox(
                  height: 200,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: []
                ),
                ),
                SizedBox(height: 16),

                //Section
            ],
          ),
      ),
    ),
    );
  }
}
