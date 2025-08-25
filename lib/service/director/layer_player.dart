import 'dart:io';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:video_player/video_player.dart';

class LayerPlayer {
  final Layer layer;
  int currentAssetIndex = -1;
  late VideoPlayerController _videoController;
  VideoPlayerController get videoController => _videoController;

  LayerPlayer(this.layer);

  Future<void> initialize() async {
    // No playlist: just initialize with the first video asset if available
    Asset? videoAsset;
    try {
      videoAsset = layer.assets.firstWhere((a) => a.type == AssetType.video);
    } catch (_) {
      videoAsset = null;
    }
    if (videoAsset != null) {
      _videoController = VideoPlayerController.file(File(videoAsset.srcPath));
      await _videoController.initialize();
    }
  }

  Future<void> preview(int pos) async {
    final assetIndex = getAssetByPosition(pos);
    if (assetIndex == -1) return;
    final asset = layer.assets[assetIndex];
    if (asset.type != AssetType.video) return;
    if (_videoController.value.isInitialized) {
      await _videoController.pause();
      await _videoController.seekTo(
        Duration(milliseconds: pos - (asset.begin ?? 0)),
      );
      await _videoController.setVolume(0);
      await _videoController.play();
      await _videoController.pause();
    }
  }

  Future<void> play(int pos) async {
    final assetIndex = getAssetByPosition(pos);
    if (assetIndex == -1) return;
    final asset = layer.assets[assetIndex];
    if (asset.type != AssetType.video) return;
    if (_videoController.value.isInitialized) {
      await _videoController.pause();
      await _videoController.seekTo(
        Duration(milliseconds: pos - (asset.begin ?? 0)),
      );
      await _videoController.setVolume(layer.volume);
      await _videoController.play();
    }
  }

  int getAssetByPosition(int? pos) {
    if (pos == null) return -1;
    for (int i = 0; i < layer.assets.length; i++) {
      final asset = layer.assets[i];
      if ((asset.begin ?? 0) + (asset.duration ?? 0) - 1 >= pos) {
        return i;
      }
    }
    return -1;
  }

  Future<void> stop() async {
    if (_videoController.value.isInitialized) {
      await _videoController.pause();
    }
  }

  Future<void> dispose() async {
    await _videoController.dispose();
  }
}
