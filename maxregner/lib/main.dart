import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/gemini_service.dart';
import 'services/voice_service.dart';
import 'services/accessibility_service_handler.dart';
import 'services/app_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaxRegnerApp());
}

class MaxRegnerApp extends StatelessWidget {
  const MaxRegnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaxRegner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GeminiService _geminiService = GeminiService();
  final VoiceService _voiceService = VoiceService();
  final List<Map<String, String>> _messages = [];
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _geminiService.init();
    await _voiceService.init();
    await Permission.microphone.request();
    setState(() {
      _isInitializing = false;
    });
  }

  void _handleVoiceCommand() {
    if (_voiceService.isListening) {
      _voiceService.stopListening();
    } else {
      _voiceService.listen((text) {
        _processCommand(text);
      });
    }
    setState(() {});
  }

  Future<void> _processCommand(String text) async {
    setState(() {
      _messages.add({"role": "user", "text": text});
    });

    String response = await _geminiService.getResponse(text);

    // Parse commands from response
    String cleanResponse = response;
    if (response.contains("COMMAND_START")) {
      final startIndex = response.indexOf("COMMAND_START") + "COMMAND_START".length;
      final endIndex = response.indexOf("COMMAND_END");
      if (endIndex > startIndex) {
        final commandJson = response.substring(startIndex, endIndex).trim();
        cleanResponse = response.substring(0, response.indexOf("COMMAND_START")).trim();
        _executeCommand(commandJson);
      }
    }

    setState(() {
      _messages.add({"role": "max", "text": cleanResponse});
    });
    _voiceService.speak(cleanResponse);
  }

  void _executeCommand(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      final action = data['action'];
      if (action == 'open_app') {
        AppService.openApp(data['package']);
      } else if (action == 'system_action') {
        AccessibilityServiceHandler.performAction(data['type']);
      }
    } catch (e) {
      debugPrint("Error parsing command: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("MaxRegner AI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen(geminiService: _geminiService)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg['text'] ?? ""),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: FloatingActionButton.large(
              onPressed: _handleVoiceCommand,
              child: Icon(_voiceService.isListening ? Icons.mic : Icons.mic_none),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final GeminiService geminiService;
  const SettingsScreen({super.key, required this.geminiService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // In a real app we'd load the current key here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Gemini API Key",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await widget.geminiService.setApiKey(_controller.text);
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => AccessibilityServiceHandler.requestPermission(),
              child: const Text("Enable Accessibility Service"),
            ),
          ],
        ),
      ),
    );
  }
}
