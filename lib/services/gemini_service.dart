import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey = 'AIzaSyB0aVu27o3IJQbHc2qC-ynATNVWA6wX0iA';  // Replace with your actual API key
  late final GenerativeModel model;

  GeminiService() {
    // Update the model version here
    model = GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);
  }

  Future<String> identifyPokemon(String imagePath) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final content = [
        Content.multi([
          TextPart('Identify this Pokémon'),
          DataPart('image/png', imageBytes),
        ])
      ];

      // Make the API request and process the response
      final response = await model.generateContent(content);
      if (response.text != null && response.text!.isNotEmpty) {
        return _extractPokemonName(response.text!);
      } else {
        return 'No identification result found';
      }
    } catch (e) {
      return 'Error identifying Pokémon: $e';
    }
  }

  String _extractPokemonName(String responseText) {
    // Define regex patterns to match the Pokémon name in the response
    final patterns = [
      RegExp(r'\b(?:This is|That Pokémon is|It is|The Pokémon is)\s+(\w+)', caseSensitive: false),
      RegExp(r'\b(?:This looks like|It looks like|Appears to be|Looks like)\s+(\w+)', caseSensitive: false),
      RegExp(r'\b(?:Identified as|Recognized as)\s+(\w+)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(responseText);
      if (match != null) {
        return match.group(1)!.replaceAll('.', '');
      }
    }

    // If no pattern matches, return the response text without punctuation
    return responseText.replaceAll('.', '').trim();
  }
}
