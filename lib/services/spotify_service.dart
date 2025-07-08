import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;

/// A service for both fetching user data and creating new playlists.
class SpotifyService {
  final oauth2.Client _client;

  SpotifyService(this._client);

  // Test if token is valid
  Future<bool> _isTokenValid() async {
    try {
      final response = await _client.get(
        Uri.parse('https://api.spotify.com/v1/me'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetches the current user's Spotify ID.
  Future<String> getCurrentUserId() async {
    final response = await _client.get(Uri.parse('https://api.spotify.com/v1/me'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'] as String;
    } else {
      throw Exception('Failed to get user ID: ${response.statusCode}');
    }
  }

  /// Creates a new (private) playlist for [userId] with [name] and optional [description].
  /// Returns the new playlist's ID.
  

  /// Adds a list of Spotify track URIs to the given [playlistId].
  /// Handles batching automatically to respect Spotify's 100-track limit per request.
  Future<String> createPlaylist(String userId, String name, {String description = ''}) async {
  try {
    final response = await _client.post(
      Uri.parse('https://api.spotify.com/v1/users/$userId/playlists'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'description': description,
        'public': false,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['id'] as String;
    } else {
      throw Exception('Failed to create playlist: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Create playlist error: $e');
    rethrow;
  }
}

Future<void> addTracksToPlaylist(String playlistId, List<String> trackUris) async {
  try {
    const batchSize = 100;
    for (int i = 0; i < trackUris.length; i += batchSize) {
      final batch = trackUris.sublist(
        i, 
        i + batchSize > trackUris.length ? trackUris.length : i + batchSize
      );
      
      final response = await _client.post(
        Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'uris': batch}),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add tracks: ${response.statusCode} - ${response.body}');
      }
    }
  } catch (e) {
    print('Add tracks error: $e');
    rethrow;
  }
}

  // Get user's playlists with all required fields
  Future<List<SpotifyPlaylist>> getUserPlaylists() async {
    try {
      if (!await _isTokenValid()) {
        throw Exception('Token expired - please reconnect to Spotify');
      }

      final response = await _client.get(
        Uri.parse('https://api.spotify.com/v1/me/playlists?limit=50'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['items'] as List)
            .map((item) => SpotifyPlaylist.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to fetch playlists: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Updated getPlaylistTracks method with GPT's improved version
  Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId) async {
    List<Map<String, dynamic>> allTracks = [];
    int offset = 0;
    const limit = 50; // Max per request
    int totalTracks = 0;
    try {
      do {
        final response = await _client.get(
          Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks?limit=$limit&offset=$offset'),
        );
        if (response.statusCode != 200) {
          print('Error fetching tracks: ${response.statusCode} - ${response.body}');
          break;
        }
        final data = json.decode(response.body);
        totalTracks = data['total'] ?? 0;
        
        final items = data['items'] as List;
        for (var item in items) {
          if (item['track'] != null) {
            final track = item['track'];
            allTracks.add({
              'id': track['id'],
              'name': track['name'],
              'artists': (track['artists'] as List)
                  .map<String>((a) => a['name'] as String)
                  .join(', '),
            });
          }
        }
        
        offset += limit;
      } while (allTracks.length < totalTracks && allTracks.length % limit == 0);
    } catch (e) {
      print('Error in getPlaylistTracks: $e');
    }
    print('Fetched ${allTracks.length} tracks');
    return allTracks;
  }
}

// Updated data models with URI field
class SpotifyPlaylist {
  final String id;
  final String name;
  final String? description;
  final int totalTracks;
  final String? imageUrl;

  SpotifyPlaylist({
    required this.id,
    required this.name,
    this.description,
    required this.totalTracks,
    this.imageUrl,
  });

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    int tracks = 0;
    if (json['tracks'] != null && json['tracks'] is Map) {
      tracks = json['tracks']['total'] ?? 0;
    }

    String? imgUrl;
    if (json['images'] != null &&
        json['images'] is List &&
        (json['images'] as List).isNotEmpty) {
      final firstImage = (json['images'] as List)[0];
      if (firstImage['url'] != null) {
        imgUrl = firstImage['url'].toString();
      }
    }

    return SpotifyPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Playlist',
      description: json['description']?.toString(),
      totalTracks: tracks,
      imageUrl: imgUrl,
    );
  }
}

class SpotifyTrack {
  final String id;
  final String name;
  final List<SpotifyArtist> artists;
  final SpotifyAlbum album;
  final int durationMs;
  final int popularity;
  final bool explicit;
  final String uri; // Added URI field

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artists,
    required this.album,
    required this.durationMs,
    required this.popularity,
    required this.explicit,
    required this.uri, // Added in constructor
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Track',
      artists: (json['artists'] as List)
          .map((artist) => SpotifyArtist.fromJson(artist))
          .toList(),
      album: SpotifyAlbum.fromJson(json['album']),
      durationMs: json['duration_ms'] ?? 0,
      popularity: json['popularity'] ?? 0,
      explicit: json['explicit'] ?? false,
      uri: json['uri'] ?? '', // Added URI parsing
    );
  }
}

class SpotifyArtist {
  final String name;

  SpotifyArtist({required this.name});

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    return SpotifyArtist(name: json['name'] ?? 'Unknown Artist');
  }
}

class SpotifyAlbum {
  final String name;
  final String releaseDate;

  SpotifyAlbum({required this.name, required this.releaseDate});

  factory SpotifyAlbum.fromJson(Map<String, dynamic> json) {
    return SpotifyAlbum(
      name: json['name'] ?? 'Unknown Album',
      releaseDate: json['release_date'] ?? '',
    );
  }
}