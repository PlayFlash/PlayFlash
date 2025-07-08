import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:playflash/services/spotify_auth.dart';
import 'package:playflash/services/spotify_service.dart';
import 'package:playflash/services/gemini_service.dart';
import 'package:playflash/secrets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isConnected = false;
  bool _isLoadingPlaylists = false;
  bool _isCheckingAuth = true;
  oauth2.Client? _client;
  SpotifyService? _spotifyService;
  List<SpotifyPlaylist> _playlists = [];
  final GeminiService _geminiService = GeminiService(Secrets.geminiApiKey);
  Map<String, bool> _classifyingPlaylists = {};
  Map<String, bool> _creatingPlaylists = {};
  String? _newPlaylistId;
  String? _newPlaylistName;

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    try {
      final client = await SpotifyAuth.loadSavedTokens();
      setState(() {
        _isConnected = client != null;
        _client = client;
        _spotifyService = client != null ? SpotifyService(client) : null;
        _isCheckingAuth = false;
      });
      if (_isConnected) await _loadPlaylists();
    } catch (e) {
      setState(() => _isCheckingAuth = false);
      print('Auth Error: $e');
    }
  }

  Future<void> _connectSpotify() async {
    try {
      final client = await SpotifyAuth.login(context);
      setState(() {
        _isConnected = true;
        _client = client;
        _spotifyService = SpotifyService(client);
      });
      await _loadPlaylists();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadPlaylists() async {
    if (_spotifyService == null) return;
    
    setState(() => _isLoadingPlaylists = true);
    
    try {
      final playlists = await _spotifyService!.getUserPlaylists();
      setState(() => _playlists = playlists);
    } catch (e) {
      if (e.toString().contains('expired') || e.toString().contains('Authentication')) {
        await _handleExpiredSession();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load playlists: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingPlaylists = false);
    }
  }

  Future<void> _handleExpiredSession() async {
    await SpotifyAuth.clearSavedTokens();
    setState(() {
      _isConnected = false;
      _client = null;
      _spotifyService = null;
      _playlists = [];
    });
  }

  Future<void> _classifyAndCreatePlaylist(SpotifyPlaylist playlist) async {
  setState(() => _classifyingPlaylists[playlist.id] = true);

  try {
    final tracks = await _spotifyService!.getPlaylistTracks(playlist.id);
    if (tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${playlist.name} is empty')),
      );
      return;
    }

    final trackTitles = tracks.map((t) => t['name']?.toString().trim() ?? 'Unknown').toList();
    final classification = await _geminiService.classifySongs(trackTitles);

    // Get user ID for playlist creation
    final userId = await _spotifyService!.getCurrentUserId();
    int createdCount = 0;
    
    for (final entry in classification.entries) {
      final playlistName = entry.key;
      final trackIndices = entry.value;
      
      if (trackIndices.isEmpty) continue;
      
      setState(() {
        _creatingPlaylists[playlistName] = true;
        _newPlaylistName = playlistName;
      });
      
      try {
        // Create new playlist with original name suffix
        final newPlaylistName = '$playlistName - ${playlist.name}';
        final newPlaylistId = await _spotifyService!.createPlaylist(
          userId, 
          newPlaylistName,
          description: 'Created by PlayFlash AI from ${playlist.name}'
        );
        
        setState(() {
          _newPlaylistId = newPlaylistId;
        });
        
        // Get track URIs for the classified tracks
        final trackUris = <String>[];
        for (final index in trackIndices) {
          if (index < tracks.length) {
            final trackId = tracks[index]['id']?.toString();
            if (trackId != null) {
              trackUris.add('spotify:track:$trackId');
            }
          }
        }
        
        // Add tracks to the new playlist
        if (trackUris.isNotEmpty) {
          await _spotifyService!.addTracksToPlaylist(newPlaylistId, trackUris);
          createdCount++;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created "$newPlaylistName" with ${trackUris.length} songs'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        await _handleSpotifyError(e, context);
      } finally {
        setState(() => _creatingPlaylists.remove(playlistName));
      }
    }

    if (createdCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created $createdCount playlists from ${playlist.name}')),
      );
      // Refresh playlists to show new ones
      await _loadPlaylists();
    }
  } catch (e) {
    await _handleSpotifyError(e, context);
  } finally {
    setState(() {
      _classifyingPlaylists.remove(playlist.id);
      _newPlaylistName = null;
      _newPlaylistId = null;
    });
  }
}

  Future<void> _logout() async {
    await SpotifyAuth.clearSavedTokens();
    setState(() {
      _isConnected = false;
      _client = null;
      _spotifyService = null;
      _playlists = [];
    });
  }

  Future<void> _handleSpotifyError(dynamic e, BuildContext context) async {
  if (e.toString().contains('403') && e.toString().contains('Insufficient client scope')) {
    await _logout();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New permissions required. Please reconnect to Spotify.'),
        duration: Duration(seconds: 5),
      ),
    );
  } else if (e.toString().contains('401') || e.toString().contains('expired')) {
    await _handleExpiredSession();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired. Please reconnect to Spotify.'),
        duration: Duration(seconds: 3),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isConnected 
          ? AppBar(
              backgroundColor: Colors.black,
              title: const Text(
                'Your Playlists',
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  color: Colors.white,
                ),
              ),
              actions: [
                if (_isLoadingPlaylists)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
            )
          : null,
      body: _isConnected ? _buildPlaylistUI() : _buildConnectButton(),
    );
  }

  Widget _buildConnectButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Connect to Spotify',
            style: TextStyle(
              fontFamily: 'ProductSans',
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _connectSpotify,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Continue with Spotify',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistUI() {
    if (_playlists.isEmpty) {
      return const Center(
        child: Text(
          'No playlists found',
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: Colors.white70,
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _playlists.length,
          itemBuilder: (context, index) {
            final playlist = _playlists[index];
            final isClassifying = _classifyingPlaylists[playlist.id] ?? false;

            return Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: playlist.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          playlist.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
                title: Text(
                  playlist.name,
                  style: const TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  '${playlist.totalTracks} songs',
                  style: const TextStyle(
                    fontFamily: 'ProductSans',
                    color: Colors.white70,
                  ),
                ),
                trailing: isClassifying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.auto_awesome, color: Colors.white),
                        onPressed: () => _classifyAndCreatePlaylist(playlist),
                      ),
              ),
            );
          },
        ),
        
        // Playlist creation indicator
        if (_creatingPlaylists.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Creating "${_creatingPlaylists.keys.first}"',
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_newPlaylistId != null)
                          Text(
                            'Playlist ID: ${_newPlaylistId}',
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}