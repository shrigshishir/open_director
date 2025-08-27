import 'dart:io';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:video_player/video_player.dart';

class LayerPlayer {
  Layer layer;
  int currentAssetIndex = -1;

  int _newPosition = 0;

  VideoPlayerController? _videoController;
  VideoPlayerController? get videoController => _videoController;

  void Function(int)? _onMove;
  void Function()? _onJump;
  void Function()? _onEnd;

  LayerPlayer(this.layer);

  Future<void> initialize() async {
    // Initialize with the first video asset if available
    if (layer.assets.isNotEmpty) {
      await _initializeForAsset(0);
    }
  }

  Future<void> _initializeForAsset(int assetIndex) async {
    if (assetIndex < 0 || assetIndex >= layer.assets.length) return;

    final asset = layer.assets[assetIndex];

    // Dispose previous controller if exists
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    // Only create controller for video assets
    if (asset.type == AssetType.video && !asset.deleted) {
      try {
        _videoController = VideoPlayerController.file(File(asset.srcPath));
        await _videoController!.initialize();
      } catch (e) {
        print('Error initializing video controller for ${asset.srcPath}: $e');
        _videoController = null;
      }
    }
  }

  Future<void> preview(int pos) async {
    currentAssetIndex = getAssetByPosition(pos);
    if (currentAssetIndex == -1) return;

    final asset = layer.assets[currentAssetIndex];
    if (asset.type != AssetType.video) return;

    // Initialize controller for this asset if needed
    await _initializeForAsset(currentAssetIndex);

    if (_videoController == null) return;

    _newPosition = pos - asset.begin;
    await _videoController!.setVolume(0);

    // Seek to position within the asset (considering cutFrom offset)
    final seekPosition = Duration(milliseconds: asset.cutFrom + _newPosition);
    await _videoController!.seekTo(seekPosition);
    await _videoController!.play();
    await _videoController!.pause();
  }

  Future<void> play(
    int pos, {
    void Function(int)? onMove,
    void Function()? onJump,
    void Function()? onEnd,
  }) async {
    _onMove = onMove;
    _onJump = onJump;
    _onEnd = onEnd;

    currentAssetIndex = getAssetByPosition(pos);
    if (currentAssetIndex == -1) return;

    final asset = layer.assets[currentAssetIndex];
    if (asset.type != AssetType.video) return;

    // Initialize controller for this asset if needed
    await _initializeForAsset(currentAssetIndex);

    if (_videoController == null) return;

    await _videoController!.setVolume(layer.volume ?? 1.0);
    _newPosition = pos - asset.begin;

    // Seek to position within the asset (considering cutFrom offset)
    final seekPosition = Duration(milliseconds: asset.cutFrom + _newPosition);
    await _videoController!.seekTo(seekPosition);
    await _videoController!.play();
    _videoController!.addListener(_videoListener);
  }

  int getAssetByPosition(int? pos) {
    if (pos == null) return -1;
    for (int i = 0; i < layer.assets.length; i++) {
      int assetEnd = layer.assets[i].begin + layer.assets[i].duration - 1;
      if (layer.assets[i].begin <= pos && assetEnd >= pos) {
        return i;
      }
    }
    return -1;
  }

  void _videoListener() async {
    if (_videoController == null || currentAssetIndex == -1) return;

    final asset = layer.assets[currentAssetIndex];
    final videoPosition = _videoController!.value.position.inMilliseconds;

    // Calculate the actual position in the timeline
    _newPosition = (videoPosition - asset.cutFrom) + asset.begin;

    if (_onMove != null) {
      _onMove!(_newPosition);
    }

    // Check if we've reached the end of the current asset
    final assetDuration = asset.duration;
    final relativePosition = videoPosition - asset.cutFrom;

    bool isAtEnd =
        (!_videoController!.value.isPlaying &&
        relativePosition >= assetDuration - 100);

    if (isAtEnd) {
      await stop();

      // Check if there's a next asset to play
      int nextAssetIndex = currentAssetIndex + 1;
      if (nextAssetIndex < layer.assets.length) {
        // Move to next asset
        currentAssetIndex = nextAssetIndex;
        if (_onJump != null) {
          _onJump!();
        }

        // Auto-play next asset if it's at the current timeline position
        final nextAsset = layer.assets[nextAssetIndex];
        if (nextAsset.begin <= _newPosition) {
          await _initializeForAsset(nextAssetIndex);
          if (_videoController != null) {
            await _videoController!.play();
            _videoController!.addListener(_videoListener);
          }
        }
      } else {
        // End of all assets
        currentAssetIndex = -1;
        if (_onJump != null) {
          _onJump!();
        }
        if (_onEnd != null) {
          _onEnd!();
        }
      }
    }
  }

  Future<void> stop() async {
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      await _videoController!.pause();
    }
  }

  Future<void> addMediaSource(int index, Asset asset) async {
    // This method is no longer needed with standard video_player
    // Each asset will have its own controller initialized when needed
  }

  Future<void> removeMediaSource(int index) async {
    // This method is no longer needed with standard video_player
    // Controllers are managed per asset
  }

  Future<void> dispose() async {
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }
  }
}
