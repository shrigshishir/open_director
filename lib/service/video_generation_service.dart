import 'dart:io';
import 'dart:async';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class VideoGenerationService {
  Stream<FFmpegStat> get ffmpegStatStream => _ffmpegStatController.stream;
  final StreamController<FFmpegStat> _ffmpegStatController =
      StreamController<FFmpegStat>.broadcast();

  Future<int> getVideoDuration(String path) async {
    final info = await FFprobeKit.getMediaInformation(path);
    final properties = info.getMediaInformation()?.getAllProperties() ?? {};
    final duration = properties['duration'];
    if (duration is String) {
      return (double.parse(duration) * 1000).round();
    } else if (duration is double) {
      return (duration * 1000).round();
    }
    return 0;
  }

  Future<String?> generateVideoThumbnail(
    String videoPath, {
    int positionMs = 0,
  }) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String thumbnailDir = '${appDocDir.path}/thumbnails';
      await Directory(thumbnailDir).create(recursive: true);

      final String outputPath =
          '$thumbnailDir/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final double positionSec = positionMs / 1000.0;

      final String command =
          '-i "$videoPath" -ss $positionSec -vframes 1 -y "$outputPath"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      }
      return null;
    } catch (e) {
      print('Error generating video thumbnail: $e');
      return null;
    }
  }

  Future<String?> generateImageThumbnail(String imagePath) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String thumbnailDir = '${appDocDir.path}/thumbnails';
      await Directory(thumbnailDir).create(recursive: true);

      final String outputPath =
          '$thumbnailDir/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // For images, we can just copy or resize them
      final File inputFile = File(imagePath);

      await inputFile.copy(outputPath);
      return outputPath;
    } catch (e) {
      print('Error generating image thumbnail: $e');
      return null;
    }
  }

  Future<void> generateVideo(List<Layer> layers, String outputPath) async {
    try {
      _ffmpegStatController.add(
        FFmpegStat(outputPath: outputPath, isGenerating: true, progress: 0.0),
      );

      // This is a simplified version - the full implementation would be quite complex
      // involving multiple video layers, transitions, effects, etc.
      String command = _buildFFmpegCommand(layers, outputPath);

      await FFmpegKit.executeAsync(command, (session) async {
        final returnCode = await session.getReturnCode();
        _ffmpegStatController.add(
          FFmpegStat(
            outputPath: outputPath,
            isGenerating: false,
            isCompleted: ReturnCode.isSuccess(returnCode),
            progress: 1.0,
          ),
        );
      });
    } catch (e) {
      _ffmpegStatController.add(
        FFmpegStat(
          outputPath: outputPath,
          isGenerating: false,
          isCompleted: false,
          error: e.toString(),
        ),
      );
    }
  }

  String _buildFFmpegCommand(List<Layer> layers, String outputPath) {
    // This is a basic implementation - would need to be expanded for full functionality
    final StringBuffer command = StringBuffer();

    // Add input files
    for (final layer in layers) {
      for (final asset in layer.assets) {
        if (asset.type == AssetType.video || asset.type == AssetType.audio) {
          command.write('-i "${asset.srcPath}" ');
        }
      }
    }

    // Add basic filter and output
    command.write('-c:v libx264 -c:a aac -y "$outputPath"');

    return command.toString();
  }

  void dispose() {
    _ffmpegStatController.close();
  }
}

// FFmpeg statistics model
class FFmpegStat {
  final String outputPath;
  final bool isGenerating;
  final bool isCompleted;
  final double progress;
  final String? error;

  FFmpegStat({
    this.outputPath = '',
    this.isGenerating = false,
    this.isCompleted = false,
    this.progress = 0.0,
    this.error,
  });
}
