import 'dart:async'; // Added for TimeoutException
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent';

  final String apiKey;

  GeminiService(this.apiKey);

  Future<Map<String, List<int>>> classifySongs(List<String> trackTitles) async {
    try {
      final prompt = '''
You are an expert music curator with a deep knowledge of music history (malayalam/english/hindi/tamil/international- all from 70s to latest 2025) and vibes.
Your task is to analyze a list of songs, group them into thematic clusters based on genre, artist, era, mood, and instrumentation.

For each distinct cluster you identify, you must generate a creative, evocative, Spotify-styled aesthetic playlist title. The titles should be specific and cool, like "Bombay Blues – RD Burman '74" or "Indie Dusk: From Bon Iver to Mitski".

**Output Instructions:**
- You MUST output ONLY a single, valid JSON object.
- Do not include any text, explanations, or markdown fences like ```json before or after the JSON object.
- The root of the JSON object must be a key named "playlists".
- The value of "playlists" must be an array of playlist objects.
- Each playlist object in the array must have two keys:
  1. "name": A string containing the creative playlist title you generated.
  2. "songs": An array of integers, representing the 0-indexed original song numbers that belong to this playlist.

**Example Output Structure:**
{
  "playlists": [
    {
      "name": "Generated Playlist Name 1",
      "songs": [0, 5, 12, 23]
    },
    {
      "name": "Another Creative Name",
      "songs": [1, 8, 19]
    }
  ]
}

**Songs to Classify (0-indexed):**
${trackTitles.asMap().entries.map((e) => '${e.key}: ${e.value}').join('\n')}
''';

      final response = await http.post( // The http.post call remains the same, with the timeout
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8, 
            'maxOutputTokens': 8000,
            'responseMimeType': 'application/json'
          }
        }),
      ).timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          throw TimeoutException('The request to the Gemini API timed out after 2 minutes.');
        },
      );

      if (response.statusCode == 200) {
        return _processResponse(response.body);
      } else {
        print('API Error ${response.statusCode}: ${response.body}');
        throw Exception('API Error ${response.statusCode}');
      }
    } catch (e) {
      print('Classification Error: $e');
      return {}; // return an empty map on any failure
    }
  }

  Map<String, List<int>> _processResponse(String responseBody) {
    try {
      final data = json.decode(responseBody);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

      final regExp = RegExp(r'\{[\s\S]*\}');  //we use a regex to reliably find the JSON object in the response
      final match = regExp.firstMatch(text);

      if (match == null) {
        throw Exception('Could not find a valid JSON object in the response.');
      }
      final jsonString = match.group(0)!;
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      if (!jsonData.containsKey('playlists')) {
        throw Exception("JSON response does not contain the required 'playlists' key.");
      }

      final playlists = jsonData['playlists'] as List<dynamic>;
      final Map<String, List<int>> result = {};

      for (final playlistData in playlists) {
        final playlistMap = playlistData as Map<String, dynamic>;
        final name = playlistMap['name'] as String;
        
        final songIndices = (playlistMap['songs'] as List<dynamic>).cast<int>().toList(); // convert List<dynamic> (e.g., [1, 2, 3]) to List<int>
        
        if (name.isNotEmpty && songIndices.isNotEmpty) {
          result[name] = songIndices;
        }
      }
      
      return result;
      
    } catch (e) {
     
      print('JSON Processing Error: $e');  //debugging if the model messes up the format
      print('--- Full Response Body for Debugging ---');
      print(responseBody);
      print('--- End of Response Body ---');
      rethrow; 
    }
  }
}