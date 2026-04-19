import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  GenerativeModel? _model;
  String? _apiKey;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('gemini_api_key');
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey!, requestOptions: const RequestOptions(apiVersion: 'v1'));
    }
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    _apiKey = key;
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey!, requestOptions: const RequestOptions(apiVersion: 'v1'));
  }

  bool get isReady => _model != null;

  Future<String> getResponse(String prompt) async {
    if (_model == null) return "Please set your Gemini API key in settings.";

    try {
      final systemPrompt = """
You are MaxRegner, an AI assistant with full control over the user's Android phone.
Your goal is to help the user perform tasks using voice commands.
You can:
1. Open apps.
2. Change settings (volume, brightness, etc. - via instructions or accessibility if possible).
3. Provide information.

When the user gives a command that requires a system action, respond with a JSON object at the end of your message in the following format:
COMMAND_START
{
  "action": "open_app",
  "package": "com.android.settings"
}
COMMAND_END

Or for system actions:
COMMAND_START
{
  "action": "system_action",
  "type": "back"
}
COMMAND_END

Current available actions: open_app, system_action (back, home, recents, notifications, quickSettings).
""";
      final content = [Content.text(systemPrompt + "\nUser: " + prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? "No response from Gemini.";
    } catch (e) {
      return "Error: $e";
    }
  }
}
