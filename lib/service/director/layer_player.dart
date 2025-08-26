import 'package:flutter_video_editor_app/model/model.dart';
import 'package:video_player/video_player.dart';

class LayerPlayer {
  Layer layer;
  int currentAssetIndex = -1;

  int _newPosition = 0;

  late final VideoPlayerController _videoController;
  // VideoPlayerController get videoController => _videoController;

  void Function(int)? _onMove;
  void Function()? _onJump;
  void Function()? _onEnd;

  LayerPlayer(this.layer);

  Future<void> initialize() async {
    _videoController = VideoPlayerController.playList();
    await _videoController.initialize();
    for (int i = 0; i < layer.assets.length; i++) {
      await addMediaSource(i, layer.assets[i]);
    }
  }

  Future<void> preview(int pos) async {
    currentAssetIndex = getAssetByPosition(pos);
    if (currentAssetIndex == -1) return;
    if (layer.assets[currentAssetIndex].type != AssetType.video) return;
    _newPosition = pos - layer.assets[currentAssetIndex].begin;
    await _videoController.setVolume(0);
    await _videoController.seekTo(
      currentAssetIndex,
      Duration(milliseconds: _newPosition),
    );
    await _videoController.play();
    await _videoController.pause();
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
    await _videoController.setVolume(layer.volume ?? 1.0);
    _newPosition = pos - layer.assets[currentAssetIndex].begin;
    await _videoController.seekTo(
      currentAssetIndex,
      Duration(milliseconds: _newPosition),
    );
    await _videoController.play();
    _videoController.addListener(_videoListener);
  }

  int getAssetByPosition(int? pos) {
    if (pos == null) return -1;
    for (int i = 0; i < layer.assets.length; i++) {
      if (layer.assets[i].begin + layer.assets[i].duration - 1 >= pos) {
        return i;
      }
    }
    return -1;
  }

  void _videoListener() async {
    _newPosition =
        _videoController.value.position.inMilliseconds +
        layer.assets[_videoController.value.windowIndex].begin;
    if (_onMove != null) {
      _onMove!(_newPosition);
    }

    if (currentAssetIndex != _videoController.value.windowIndex) {
      currentAssetIndex = _videoController.value.windowIndex;
      if (_onJump != null) {
        _onJump!();
      }
    }

    // 100 because of the period of position updating
    bool isAtEnd =
        (!_videoController.value.isPlaying &&
        _videoController.value.position.inMilliseconds >=
            layer.assets[_videoController.value.windowIndex].duration - 100);

    if (isAtEnd) {
      await stop();
      currentAssetIndex = -1;
      if (_onJump != null) {
        _onJump!();
      }
      if (_onEnd != null) {
        _onEnd!();
      }
    }
  }

  Future<void> stop() async {
    // First remove listener because listener check status
    _videoController.removeListener(_videoListener);
    await _videoController.pause();
  }

  Future<void> addMediaSource(int index, Asset asset) async {
    if (asset.type == AssetType.image) {
      await _videoController.addMediaSource(
        index,
        'assets/blank-1h.mp4',
        asset.cutFrom,
        asset.cutFrom + asset.duration,
        isAsset: true,
      );
    } else {
      await _videoController.addMediaSource(
        index,
        asset.deleted ? 'assets/blank-1h.mp4' : asset.srcPath,
        asset.cutFrom,
        asset.cutFrom + asset.duration,
        isAsset: false,
      );
    }
  }

  Future<void> removeMediaSource(int index) async {
    await _videoController.removeMediaSource(index);
  }

  Future<void> dispose() async {
    await _videoController.dispose();
  }
}
