import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:playflash/secrets.dart';

class SpotifyAuth {
  // Credentials
  static const _clientId = Secrets.spotifyClientId;
  static const _clientSecret = Secrets.spotifyClientSecret;
  static const _redirectUri = 'playflash://callback';
  
  // Spotify OAuth endpoints
  static const _authorizationEndpoint = 'https://accounts.spotify.com/authorize';
  static const _tokenEndpoint = 'https://accounts.spotify.com/api/token';

  // Secure storage for tokens
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Save tokens securely
  static Future<void> _saveTokens(oauth2.Client client) async {
    try {
      final credentials = client.credentials;
      await _storage.write(key: 'access_token', value: credentials.accessToken);
      await _storage.write(key: 'refresh_token', value: credentials.refreshToken);
      await _storage.write(key: 'token_expiry', value: credentials.expiration?.toIso8601String());
      await _storage.write(key: 'token_scopes', value: credentials.scopes?.join(','));
      
      // Also save a simple flag in SharedPreferences for quick checking
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('spotify_authenticated', true);
      
      print('Tokens saved successfully');
    } catch (e) {
      print('Error saving tokens: $e');
    }
  }

  // IMPROVED: Network-resilient token loading
  static Future<oauth2.Client?> loadSavedTokens({bool skipRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool('spotify_authenticated') ?? false;
      
      if (!isAuthenticated) {
        print('No saved authentication found');
        return null;
      }

      final accessToken = await _storage.read(key: 'access_token');
      final refreshToken = await _storage.read(key: 'refresh_token');
      final expiryString = await _storage.read(key: 'token_expiry');
      final scopesString = await _storage.read(key: 'token_scopes');

      if (accessToken == null) {
        print('No access token found in storage');
        return null; // Don't clear tokens here - just return null
      }

      DateTime? expiry;
      if (expiryString != null) {
        try {
          expiry = DateTime.parse(expiryString);
        } catch (e) {
          print('Error parsing expiry date: $e');
        }
      }

      List<String>? scopes;
      if (scopesString != null && scopesString.isNotEmpty) {
        scopes = scopesString.split(',');
      }

      // Check if token is expired and should refresh
      final shouldRefresh = !skipRefresh && 
                           expiry != null && 
                           DateTime.now().isAfter(expiry.subtract(Duration(minutes: 5)));

      if (shouldRefresh && refreshToken != null) {
        print('Access token is expired, attempting refresh...');
        
        try {
          // Try to refresh token
          final refreshedCredentials = await _refreshTokenManually(refreshToken);
          
          if (refreshedCredentials != null) {
            final client = oauth2.Client(
              refreshedCredentials,
              identifier: _clientId,
              secret: _clientSecret,
            );
            
            await _saveTokens(client);
            print('Token refreshed successfully');
            return client;
          } else {
            print('Token refresh failed - using existing token');
            // Fall back to existing token instead of clearing
          }
        } catch (e) {
          print('Token refresh failed: $e - using existing token');
          // Continue with existing token instead of clearing
        }
      }
      
      // Create client with existing credentials (even if expired)
      final credentials = oauth2.Credentials(
        accessToken,
        refreshToken: refreshToken,
        expiration: expiry,
        scopes: scopes ?? [
          'user-read-private',
          'user-read-email',
          'playlist-modify-public',
          'playlist-modify-private',
          'playlist-read-private',
          'playlist-read-collaborative',
          'user-library-read',
        ],
      );

      final client = oauth2.Client(
        credentials,
        identifier: _clientId,
        secret: _clientSecret,
      );
      
      print('Using saved tokens (${shouldRefresh ? "refresh failed, using expired" : "not expired"})');
      return client;
      
    } catch (e) {
      print('Error loading saved tokens: $e');
      // Only clear tokens on specific errors, not all errors
      if (e.toString().contains('SecurityException') || 
          e.toString().contains('corrupt') ||
          e.toString().contains('invalid_grant')) {
        print('Clearing tokens due to security/corruption error');
        await clearSavedTokens();
      }
      return null;
    }
  }

  // Manual token refresh implementation with timeout
  static Future<oauth2.Credentials?> _refreshTokenManually(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      ).timeout(
        Duration(seconds: 30), // Add timeout to prevent hanging
        onTimeout: () {
          throw TimeoutException('Token refresh timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'] ?? refreshToken; // Spotify may not always return a new refresh token
        final expiresIn = data['expires_in']; // seconds
        
        final expiration = DateTime.now().add(Duration(seconds: expiresIn));
        
        return oauth2.Credentials(
          newAccessToken,
          refreshToken: newRefreshToken,
          expiration: expiration,
          scopes: [
            'user-read-private',
            'user-read-email',
            'playlist-modify-public',
            'playlist-modify-private',
            'playlist-read-private',
            'playlist-read-collaborative',
            'user-library-read',
          ],
        );
      } else {
        print('Token refresh failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during manual token refresh: $e');
      return null;
    }
  }

  // Clear saved tokens (for logout)
  static Future<void> clearSavedTokens() async {
    try {
      await _storage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('spotify_authenticated');
      print('Tokens cleared');
    } catch (e) {
      print('Error clearing tokens: $e');
    }
  }

  // Check if user is authenticated without network calls
  static Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool('spotify_authenticated') ?? false;
      
      if (!isAuthenticated) return false;
      
      // Verify we actually have an access token
      final accessToken = await _storage.read(key: 'access_token');
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      print('Error checking authentication status: $e');
      return false;
    }
  }

  // Updated login method with playlist modification scopes
  static Future<oauth2.Client> login(BuildContext context) async {
    try {
      // First, try to load saved tokens
      final savedClient = await loadSavedTokens();
      if (savedClient != null) {
        print('Using saved authentication');
        return savedClient;
      }

      print('Starting new authentication flow');

      // Initialize OAuth grant
      final grant = oauth2.AuthorizationCodeGrant(
        _clientId,
        Uri.parse(_authorizationEndpoint),
        Uri.parse(_tokenEndpoint),
        secret: _clientSecret,
      );

      // Generate authorization URL with playlist modification scopes
      final authUrl = grant.getAuthorizationUrl(
        Uri.parse(_redirectUri),
        scopes: [
          'user-read-private',
          'user-read-email',
          'playlist-modify-public',
          'playlist-modify-private',
          'playlist-read-private',
          'playlist-read-collaborative',
          'user-library-read',
        ],
      );

      print('Launching auth URL: $authUrl');

      // Launch the URL in browser
      final launched = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch browser');
      }

      // Listen for the callback URL with timeout
      final appLinks = AppLinks();
      late StreamSubscription subscription;
      final completer = Completer<Uri>();
      bool completed = false;

      subscription = appLinks.uriLinkStream.listen(
        (Uri uri) {
          print('Received callback: $uri');
          if (!completed) {
            completed = true;
            subscription.cancel();
            completer.complete(uri);
          }
        },
        onError: (err) {
          print('Link stream error: $err');
          if (!completed) {
            completed = true;
            subscription.cancel();
            completer.completeError(err);
          }
        },
      );

      // Set up timeout
      Timer(const Duration(minutes: 5), () {
        if (!completed) {
          completed = true;
          subscription.cancel();
          completer.completeError(Exception('Authentication timeout - no callback received after 5 minutes'));
        }
      });

      try {
        // Wait for callback
        final responseUri = await completer.future;
        
        // Check if we got an error in the callback
        if (responseUri.queryParameters.containsKey('error')) {
          throw Exception('Spotify authorization error: ${responseUri.queryParameters['error']}');
        }

        // Exchange code for tokens
        final client = await grant.handleAuthorizationResponse(responseUri.queryParameters);
        
        // Save the tokens for future use
        await _saveTokens(client);
        
        return client;
      } catch (e) {
        // If automatic callback fails, fall back to manual entry
        final client = await _handleManualAuth(context, authUrl, grant);
        
        // Save the tokens for future use
        await _saveTokens(client);
        
        return client;
      }

    } catch (e) {
      throw Exception('Spotify login failed: ${e.toString()}');
    }
  }

  static Future<oauth2.Client> _handleManualAuth(
    BuildContext context, 
    Uri authUrl, 
    oauth2.AuthorizationCodeGrant grant
  ) async {
    // Show manual instructions
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Manual Authentication Required',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Automatic redirect failed. Please follow these steps:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Copy the URL below\n2. Open it in your browser\n3. Login to Spotify\n4. After clicking "Agree", look at the browser URL bar\n5. Copy the entire URL (starting with playflash://callback) and paste it below',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                authUrl.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldContinue != true) {
      throw Exception('Authentication cancelled');
    }

    // Show URL paste dialog
    final responseUrl = await _showUrlPasteDialog(context);
    if (responseUrl == null) {
      throw Exception('No URL provided');
    }

    return await grant.handleAuthorizationResponse(responseUrl.queryParameters);
  }

  static Future<Uri?> _showUrlPasteDialog(BuildContext context) async {
    final controller = TextEditingController();
    return await showDialog<Uri>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Paste Callback URL',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'After clicking "Agree" in Spotify, look at your browser\'s address bar. Copy the entire URL that starts with "playflash://callback" and paste it here:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'playflash://callback?code=...',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                try {
                  final uri = Uri.parse(controller.text.trim());
                  Navigator.pop(context, uri);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid URL format')),
                  );
                }
              }
            },
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}