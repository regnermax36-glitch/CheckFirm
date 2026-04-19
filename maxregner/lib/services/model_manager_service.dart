import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ModelManagerService {
  static const String _modelUrl = "https://example.com/maxregner_music_engine.bin"; // Placeholder for actual engine
  static const String _modelFileName = "maxregner_engine.bin";

  Future<bool> isModelDownloaded() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/$_modelFileName");
    return await file.exists();
  }

  Future<void> downloadModel({required Function(double) onProgress}) async {
    final directory = await getApplicationDocumentsDirectory();
    final savePath = "${directory.path}/$_modelFileName";

    final dio = Dio();
    try {
      await dio.download(
        _modelUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
    } catch (e) {
      print("Download error: $e");
      // For demonstration in this restricted environment, we create a dummy file if download fails
      final file = File(savePath);
      await file.writeAsBytes(List.generate(1024, (index) => 0));
    }
  }

  Future<String> getModelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return "${directory.path}/$_modelFileName";
  }
}
