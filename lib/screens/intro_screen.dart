import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import 'help_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF121212), Color(0xFF000000)],
              ),
            ),
          ),

          Column(
            children: [
              // section1: app name and tagline
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text.rich(
  TextSpan(
    children: [
      TextSpan(
        text: 'Play ',
        style: TextStyle(
          fontFamily: 'ProductSans',
          fontSize: 42,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      TextSpan(
        text: 'Flash',
        style: TextStyle(
          fontFamily: 'Nothing',
          fontSize: 42,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4CB050), 
        ),
      ),
    ],
  ),
)
,
                      SizedBox(height: 16),
                      Text(
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

              // section2: app desc
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Center(
                    child: Text(
                      "PlayFlash is a Playlist-Focused Listening and Sorting Hub (F.L.A.S.H) that uses AI to turn your messy playlists into mood-perfect mixes!",
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

              // section3: buttons
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Okay but like... how tho?",
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

              // section4: michael jackson image
              Expanded(
                flex: 1,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -MediaQuery.of(context).size.width * 0.25,
                      bottom: -1,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 1.0,
                        height: MediaQuery.of(context).size.width * 1.3,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/images/intro_image.png"),
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
