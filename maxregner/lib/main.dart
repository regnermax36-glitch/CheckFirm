import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/music_service.dart';
import 'services/export_service.dart';
import 'services/history_service.dart';
import 'services/model_manager_service.dart';
import 'widgets/studio_waveform.dart';
import 'dart:math' as math;

void main() {
  runApp(const MaxRegnerStudioApp());
}

class MaxRegnerStudioApp extends StatelessWidget {
  const MaxRegnerStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaxRegner AI Music Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurpleAccent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          secondary: Colors.amberAccent,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A2E),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const InitializationWrapper(),
    );
  }
}

class InitializationWrapper extends StatefulWidget {
  const InitializationWrapper({super.key});

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  final ModelManagerService _modelManager = ModelManagerService();
  bool _isInitialized = false;
  double _downloadProgress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAndInit();
  }

  Future<void> _checkAndInit() async {
    try {
      if (await _modelManager.isModelDownloaded()) {
        setState(() => _isInitialized = true);
      } else {
        await _modelManager.downloadModel(
          onProgress: (p) => setState(() => _downloadProgress = p),
        );
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) return const StudioScreen();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, size: 80, color: Colors.deepPurpleAccent),
              const SizedBox(height: 32),
              const Text(
                "Initializing MaxRegner Engine",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "Downloading high-quality offline AI models. This happens only once.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Text("${(_downloadProgress * 100).toInt()}%"),
              if (_error != null) ...[
                const SizedBox(height: 24),
                Text("Error: $_error", style: const TextStyle(color: Colors.redAccent)),
                TextButton(onPressed: _checkAndInit, child: const Text("Retry")),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> with SingleTickerProviderStateMixin {
  final MusicGenerationService _musicService = MusicGenerationService();
  final ExportService _exportService = ExportService();
  final HistoryService _historyService = HistoryService();
  final ModelManagerService _modelManager = ModelManagerService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _promptController = TextEditingController();

  double _durationInMinutes = 1.0;
  int _bpm = 120;
  String _selectedKey = 'C Major';
  final List<String> _selectedInstruments = ['Piano', 'Drums'];
  final List<String> _availableInstruments = ['Piano', 'Drums', 'Bass', 'Guitar', 'Synth', 'Strings', 'Brass'];
  final List<String> _availableKeys = ['C Major', 'G Major', 'D Major', 'A Major', 'E Major', 'F Major', 'A Minor', 'E Minor'];

  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String? _lastGeneratedPath;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  List<HistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _currentPosition = p));
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _totalDuration = d));
    _audioPlayer.onPlayerStateChanged.listen((s) {
      setState(() => _isPlaying = s == PlayerState.playing);
    });
  }

  Future<void> _loadHistory() async {
    final h = await _historyService.getHistory();
    setState(() => _history = h);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a prompt for your music.")),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationProgress = 0.0;
      _lastGeneratedPath = null;
    });

    try {
      final modelPath = await _modelManager.getModelPath();
      final path = await _musicService.generateMusic(
        prompt: _promptController.text,
        durationSeconds: (_durationInMinutes * 60).toInt(),
        bpm: _bpm,
        key: _selectedKey,
        instruments: _selectedInstruments,
        modelPath: modelPath,
        onProgress: (p) => setState(() => _generationProgress = p),
      );

      final newItem = HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: _promptController.text,
        path: path,
        timestamp: DateTime.now(),
        duration: (_durationInMinutes * 60).toInt(),
        bpm: _bpm,
        key: _selectedKey,
      );
      await _historyService.saveItem(newItem);
      await _loadHistory();

      setState(() {
        _lastGeneratedPath = path;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Music generated successfully!")),
      );
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _playPause([String? path]) async {
    final pathToPlay = path ?? _lastGeneratedPath;
    if (pathToPlay == null) return;

    if (_isPlaying && path == null) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(pathToPlay));
      if (path != null) setState(() => _lastGeneratedPath = path);
    }
  }

  Future<void> _export() async {
    if (_lastGeneratedPath == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final mp3Path = await _exportService.exportToMp3(_lastGeneratedPath!);
    if (mounted) Navigator.pop(context);

    if (mp3Path != null) {
      await _exportService.shareMp3(mp3Path);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to export MP3.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1E), Color(0xFF1E1E3F)],
          ),
        ),
        child: SafeArea(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildHeader(),
                ),
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.create), text: "Studio"),
                    Tab(icon: Icon(Icons.history), text: "History"),
                  ],
                  indicatorColor: Colors.deepPurpleAccent,
                  labelColor: Colors.deepPurpleAccent,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildStudioTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromptInput(),
          const SizedBox(height: 24),
          _buildAdvancedParams(),
          const SizedBox(height: 24),
          _buildDurationSelector(),
          const SizedBox(height: 32),
          _buildGenerateButton(),
          if (_isGenerating) _buildProgressIndicator(),
          if (_lastGeneratedPath != null) ...[
            const SizedBox(height: 40),
            _buildPlaybackCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return const Center(child: Text("No tracks generated yet. Start creating!"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.music_note, color: Colors.amberAccent),
            title: Text(item.prompt, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text("${item.duration}s • ${item.bpm} BPM • ${item.key}"),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill, size: 32, color: Colors.deepPurpleAccent),
              onPressed: () => _playPause(item.path),
            ),
            onTap: () => setState(() => _lastGeneratedPath = item.path),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.music_note, color: Colors.deepPurpleAccent, size: 32),
            ),
            const SizedBox(width: 16),
            const Text(
              "MaxRegner",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        const Text(
          "OFFLINE AI MUSIC STUDIO",
          style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPromptInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _promptController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Describe the music you want to create...\n(e.g., 'A lo-fi hip hop beat with rainy vibes')",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedParams() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Advanced Parameters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildParamCard("BPM", _bpm.toString(), () {
                _showBpmPicker();
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildParamCard("Key", _selectedKey, () {
                _showKeyPicker();
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text("Instruments", style: TextStyle(fontSize: 14, color: Colors.grey)),
        Wrap(
          spacing: 8,
          children: _availableInstruments.map((inst) {
            final isSelected = _selectedInstruments.contains(inst);
            return FilterChip(
              label: Text(inst),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) _selectedInstruments.add(inst);
                  else _selectedInstruments.remove(inst);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildParamCard(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
            ],
          ),
        ),
      ),
    );
  }

  void _showBpmPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Select BPM", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListWheelScrollView(
                itemExtent: 40,
                onSelectedItemChanged: (index) => setState(() => _bpm = 60 + index),
                children: List.generate(140, (index) => Center(child: Text("${60 + index}"))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKeyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: _availableKeys.map((key) => ListTile(
          title: Text(key),
          onTap: () {
            setState(() => _selectedKey = key);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Track Duration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _durationInMinutes,
                min: 0.5,
                max: 5.0,
                divisions: 9,
                label: "${_durationInMinutes.toStringAsFixed(1)} min",
                onChanged: (val) => setState(() => _durationInMinutes = val),
              ),
            ),
            Text("${_durationInMinutes.toStringAsFixed(1)} min", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _startGeneration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isGenerating
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("GENERATE MUSIC", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _generationProgress,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            borderRadius: BorderRadius.circular(10),
            minHeight: 10,
          ),
          const SizedBox(height: 8),
          Text("Synthesizing high-quality audio... ${(_generationProgress * 100).toInt()}%", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildPlaybackCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            StudioWaveform(isPlaying: _isPlaying),
            const SizedBox(height: 24),
            Slider(
              value: _currentPosition.inMilliseconds.toDouble(),
              max: _totalDuration.inMilliseconds.toDouble() > 0 ? _totalDuration.inMilliseconds.toDouble() : 1.0,
              onChanged: (val) => _audioPlayer.seek(Duration(milliseconds: val.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_currentPosition)),
                Text(_formatDuration(_totalDuration)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: _playPause,
                  iconSize: 48,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.download_rounded),
              label: const Text("EXPORT HIGH-QUALITY MP3"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.deepPurpleAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
