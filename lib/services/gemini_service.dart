import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite-preview-06-17:generateContent';
  final String apiKey;

  GeminiService(this.apiKey);

  Future<Map<String, List<int>>> classifySongs(List<String> trackTitles) async {
    try {
      final prompt = '''
Classify these songs into exactly one mood-based playlist each based on vibe and style.

Playlist Categories:
* Chill Love
* Heartbreak
* Dance Hits
* Party Starter
* Wedding Vibes
* Late Night
* Lo fi
* Wake Up
* Retro Party
* Soulful
* Acoustic
* Hot Hits
* Workout

Output JSON structure exactly:
{
  "mapping": { "0": "Chill Love", "1": "Workout", "2": "Dance Hits", ... }
}

Songs (0-indexed):
${trackTitles.asMap().entries.map((e) => '${e.key}: ${e.value}').join('\n')}
''';

      final response = await http.post(
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
            'temperature': 0.7,
            'maxOutputTokens': 2000,
            'responseMimeType': 'application/json'
          }
        }),
      );

      if (response.statusCode == 200) {
        return _processResponse(response.body);
      } else {
        print('API Error ${response.statusCode}: ${response.body}');
        throw Exception('API Error ${response.statusCode}');
      }
    } catch (e) {
      print('Classification Error: $e');
      return {};
    }
  }

  Map<String, List<int>> _processResponse(String responseBody) {
    try {
      final data = json.decode(responseBody);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;
      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw Exception('Invalid JSON response');
      }
      final jsonString = text.substring(jsonStart, jsonEnd);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      
      // process the mapping to group songs by playlist
      final mapping = jsonData['mapping'] as Map<String, dynamic>;
      final Map<String, List<int>> result = {};
      
      mapping.forEach((indexStr, playlistName) {
        final index = int.tryParse(indexStr);
        if (index != null && playlistName is String) {
          if (!result.containsKey(playlistName)) {
            result[playlistName] = [];
          }
          result[playlistName]!.add(index);
        }
      });
      
      return result;
    } catch (e) {
      print('JSON Processing Error: $e');
      return {};
    }
  }
}