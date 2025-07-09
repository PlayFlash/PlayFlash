import 'package:flutter/material.dart';
import 'about_screen.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> helpSteps = const [
    {
      'image': 'assets/images/help/1.jpg',
      'caption': 'Step 1: Click on Let`s roll and select Continue to Spotify',
    },

    {
      'image': 'assets/images/help/2.jpg',
      'caption': 'Step 2: Log in with your Spotify Credentials',
    },

    {
      'image': 'assets/images/help/3.jpg',
      'caption': 'Step 3: Give access to PlayFlash',
    },

    {
      'image': 'assets/images/help/4.jpg',
      'caption': 'Step 4: PlayFlash displays all your playlists, click on the ✨ next to any playlist to begin the show',
    },

    {
      'image': 'assets/images/help/5.jpg',
      'caption': 'Let it cook 🍳- PlayFlash builds mood playlists and adds `em to your Spotify',
    },

    {
      'images': [
        'assets/images/help/6a.jpg',
        'assets/images/help/6b.jpg',
        'assets/images/help/6c.jpg'
      ],
      'caption': 'Playlists dropping one by one... all sorted by vibe 🎶',
    },

    {
      'image': 'assets/images/help/7.jpg',
      'caption': 'Unorganized playlists? Not anymore. PlayFlash cleaned it up and delivered the vibes! 👾',
    },

    {
      'image': 'assets/images/help/8.jpg',
      'caption': 'All done, now fire up Spotify: your vibe-sorted playlists are ready to go!',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF000000)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 70), // space for AppBar

              // Carousel with images
              Expanded(
                child: Column(
                  children: [
                    // Image carousel
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        itemCount: helpSteps.length,
                        itemBuilder: (context, index) {
                          final step = helpSteps[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: step['images'] != null
                                ? // Multiple images in one slide (for 6a, 6b, 6c)
                                Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: (step['images'] as List<String>)
                                        .map((imagePath) => Container(
                                              margin: const EdgeInsets.symmetric(vertical: 4),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.asset(
                                                  imagePath,
                                                  fit: BoxFit.contain,
                                                  height: 120,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  )
                                : // Single image
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      step['image']!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        helpSteps.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == index
                                ? const Color(0xFF1DB954)
                                : Colors.white30,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Caption area
                    Container(
                      height: 80,
                      alignment: Alignment.center,
                      child: helpSteps[_currentIndex]['caption'] != null
                          ? Text(
                              helpSteps[_currentIndex]['caption']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Spotify-styled About button
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954), // Spotify green
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    elevation: 0,
                  ),
                  child: const Text(
                    "About",
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}