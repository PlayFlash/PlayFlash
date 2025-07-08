import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  void _showNeedHelp(BuildContext context) {
    //how does this work
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF121212), Color(0xFF000000)],
              ),
            ),
          ),

          // Divided layout with image in bottom-left
          Column(
            children: [
              // Section 1: Top 25% (App name and headline)
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "PlayFlash",
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 42,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "One Playlist? That's Cute.",
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Section 2: Middle 25% (Description)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Center(
                    child: Text(
                      "PlayFlash is a Playlist-Focused Listening and Sorting Hub that uses AI to turn your messy playlists into mood-perfect mixes!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),

              // Section 3: Bottom 25% (Buttons)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomButton(
                        text: "Let's roll",
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _showNeedHelp(context),
                        child: const Text(
                          "How does this work?",
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Section 4: Image (now larger and properly aligned)
              Expanded(
                flex: 1,
                child: Stack(
                  clipBehavior: Clip.none, // Allows image to overflow
                  children: [
                    Positioned(
                      left: -MediaQuery.of(context).size.width * 0.25,
                      bottom: -1,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 1.0,
                        height: MediaQuery.of(context).size.width * 1.3,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              "assets/images/intro_image.png",
                            ),
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomLeft,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}