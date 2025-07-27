import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    
    try {
      if (uri.scheme == 'mailto') {
        await launchUrl(uri);
        return;
      }
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showLaunchError(context, url);
      }
    } catch (e) {
      _showLaunchError(context, url);
    }
  }

  void _showLaunchError(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not launch: ${_simplifyUrl(url)}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _simplifyUrl(String url) {
    if (url.startsWith('mailto:')) return 'email app';
    if (url.startsWith('https://')) {
      return url.replaceFirst('https://', '').split('/').first;
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: Lottie.asset(
                  'assets/about.json',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Created with ❤️ by ash!',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),
              // gitHub card
              _buildInfoCard(
                context,
                icon: Icons.code,
                text: 'Liked it? Drop a ☆ on GitHub',
                url: 'https://github.com/a5xwin/PlayFlash',
              ),
              // email card
              _buildInfoCard(
                context,
                icon: Icons.email,
                text: "Got thoughts? I'm all ears!",
                url: 'mailto:ashmercesletifercoc@gmail.com',
              ),
              // portfolio card
              _buildInfoCard(
                context,
                icon: Icons.public,
                text: 'Check out the rest of my stuff',
                url: 'https://ashwinsajeev-dtv0.onrender.com/',
              ),
              // spotify card
              _buildInfoCard(
                context,
                icon: Icons.music_note,
                text: 'Music lover? Let\'s blend on Spotify!',
                url: 'https://open.spotify.com/user/31hgeenw72q6udi3kc5nrnp5vvai',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String url,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFFF5F5F5),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1DB954)),
        title: Text(
          text,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        onTap: () => _launchURL(url, context),
      ),
    );
  }
}