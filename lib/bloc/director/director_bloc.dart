import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/model/project.dart';
import 'package:flutter_video_editor_app/repository/project_repository.dart';
import 'package:flutter_video_editor_app/utils/layer_player.dart';
import 'director_event.dart';
import 'director_state.dart';

class DirectorBloc extends Bloc<DirectorEvent, DirectorState> {
  final ProjectRepository _projectRepository;

  Project? _project;
  List<Layer> _layers = [];
  List<LayerPlayer?> _layerPlayers = [];
  bool _isInitialized = false;

  // Flags for concurrency
  bool isEntering = false;
  bool isExiting = false;
  bool isPlaying = false;
  bool isPreviewing = false;
  bool isDragging = false;
  bool isGenerating = false;

  static const double DEFAULT_PIXELS_PER_SECONDS = 100.0 / 5.0;
  late ScrollController _scrollController;

  Timer? _playbackTimer;

  DirectorBloc({ProjectRepository? projectRepository})
    : _projectRepository = projectRepository ?? ProjectRepository(),
      super(DirectorInitial()) {
    _scrollController = ScrollController();

    on<InitializeDirector>(_onInitializeDirector);
    on<UpdatePosition>(_onUpdatePosition);
    on<PlayPause>(_onPlayPause);
    on<SelectAsset>(_onSelectAsset);
    on<ScaleTimeline>(_onScaleTimeline);
    on<DragAsset>(_onDragAsset);
    on<AddAsset>(_onAddAsset);
    on<RemoveAsset>(_onRemoveAsset);
    on<SaveProject>(_onSaveProject);
    on<StartEditingTextAsset>(_onStartEditingTextAsset);
    on<StopEditingTextAsset>(_onStopEditingTextAsset);
    on<StartEditingColor>(_onStartEditingColor);
    on<StopEditingColor>(_onStopEditingColor);
    on<UpdateTextAsset>(_onUpdateTextAsset);
    on<UpdatePreview>(_onUpdatePreview);
    on<ScaleStart>(_onScaleStart);
    on<ScaleUpdate>(_onScaleUpdate);
    on<ScaleEnd>(_onScaleEnd);
    on<EndScroll>(_onEndScroll);
  }

  @override
  Future<void> close() {
    _playbackTimer?.cancel();
    _scrollController.dispose();
    _disposeLayerPlayers();
    return super.close();
  }

  void _disposeLayerPlayers() {
    for (final player in _layerPlayers) {
      player?.dispose();
    }
    _layerPlayers.clear();
  }

  Future<void> _onInitializeDirector(
    InitializeDirector event,
    Emitter<DirectorState> emit,
  ) async {
    try {
      emit(DirectorLoading());

      _project = event.project;

      if (event.project.layersJson == null) {
        _layers = [
          Layer(type: "raster", volume: 0.1),
          Layer(type: "vector"),
          Layer(type: "audio", volume: 1.0),
        ];
      } else {
        _layers = List<Layer>.from(
          json
              .decode(event.project.layersJson!)
              .map((layerMap) => Layer.fromJson(layerMap)),
        ).toList();
      }

      _isInitialized = true;

      // Initialize layer players
      _disposeLayerPlayers();
      _layerPlayers = List<LayerPlayer?>.filled(
        _layers.length,
        null,
        growable: false,
      );

      for (int i = 0; i < _layers.length; i++) {
        if (i != 1) {
          // Skip text layer
          final layerPlayer = LayerPlayer(_layers[i]);
          await layerPlayer.initialize();
          _layerPlayers[i] = layerPlayer;
        }
      }

      final filesNotExist = _checkSomeFileNotExists();

      emit(
        DirectorLoaded(
          project: event.project,
          layers: _layers,
          scrollController: _scrollController,
          filesNotExist: filesNotExist,
        ),
      );
    } catch (e) {
      emit(DirectorError(e.toString()));
    }
  }

  Future<void> _onUpdatePosition(
    UpdatePosition event,
    Emitter<DirectorState> emit,
  ) async {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;

      // Update layer players positions
      await _updatePlayersPosition(event.position);

      emit(currentState.copyWith(position: event.position));
    }
  }

  Future<void> _onPlayPause(
    PlayPause event,
    Emitter<DirectorState> emit,
  ) async {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      final newIsPlaying = !currentState.isPlaying;

      if (newIsPlaying) {
        _startPlayback();
      } else {
        _stopPlayback();
      }

      emit(currentState.copyWith(isPlaying: newIsPlaying));
    }
  }

  void _onSelectAsset(SelectAsset event, Emitter<DirectorState> emit) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      emit(
        currentState.copyWith(
          selectedLayerIndex: event.layerIndex,
          selectedAssetIndex: event.assetIndex,
          clearEditingTextAsset: true,
          clearEditingColorType: true,
        ),
      );
    }
  }

  void _onScaleTimeline(ScaleTimeline event, Emitter<DirectorState> emit) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      final newPixelsPerSecond = (currentState.pixelsPerSecond * event.scale)
          .clamp(0.5, 100.0);
      emit(currentState.copyWith(pixelsPerSecond: newPixelsPerSecond));
    }
  }

  void _onDragAsset(DragAsset event, Emitter<DirectorState> emit) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      if (event.layerIndex >= 0 &&
          event.layerIndex < _layers.length &&
          event.assetIndex >= 0 &&
          event.assetIndex < _layers[event.layerIndex].assets.length) {
        final asset = _layers[event.layerIndex].assets[event.assetIndex];
        final deltaMs = (event.deltaX / currentState.pixelsPerSecond * 1000)
            .round();

        // Update asset position
        asset.begin = math.max(0, asset.begin + deltaMs);

        emit(currentState.copyWith(layers: List.from(_layers)));
      }
    }
  }

  void _onAddAsset(AddAsset event, Emitter<DirectorState> emit) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      if (event.layerIndex >= 0 && event.layerIndex < _layers.length) {
        _layers[event.layerIndex].assets.add(event.asset);
        emit(currentState.copyWith(layers: List.from(_layers)));
      }
    }
  }

  void _onRemoveAsset(RemoveAsset event, Emitter<DirectorState> emit) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      if (event.layerIndex >= 0 &&
          event.layerIndex < _layers.length &&
          event.assetIndex >= 0 &&
          event.assetIndex < _layers[event.layerIndex].assets.length) {
        _layers[event.layerIndex].assets.removeAt(event.assetIndex);
        emit(
          currentState.copyWith(
            layers: List.from(_layers),
            selectedLayerIndex: -1,
            selectedAssetIndex: -1,
          ),
        );
      }
    }
  }

  Future<void> _onSaveProject(
    SaveProject event,
    Emitter<DirectorState> emit,
  ) async {
    if (state is DirectorLoaded && _project != null) {
      try {
        final currentState = state as DirectorLoaded;
        _project!.layersJson = json.encode(
          _layers.map((e) => e.toJson()).toList(),
        );
        _project!.duration = _calculateDuration();
        await _projectRepository.updateProject(_project!);

        emit(currentState.copyWith(project: _project!));
      } catch (e) {
        emit(DirectorError('Failed to save project: ${e.toString()}'));
      }
    }
  }

  void _onStartEditingTextAsset(
    StartEditingTextAsset event,
    Emitter<DirectorState> emit,
  ) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      emit(currentState.copyWith(editingTextAsset: event.asset));
    }
  }

  void _onStopEditingTextAsset(
    StopEditingTextAsset event,
    Emitter<DirectorState> emit,
  ) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      emit(currentState.copyWith(clearEditingTextAsset: true));
    }
  }

  void _onStartEditingColor(
    StartEditingColor event,
    Emitter<DirectorState> emit,
  ) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      emit(currentState.copyWith(editingColorType: event.colorType));
    }
  }

  void _onStopEditingColor(
    StopEditingColor event,
    Emitter<DirectorState> emit,
  ) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      emit(currentState.copyWith(clearEditingColorType: true));
    }
  }

  void _onUpdateTextAsset(UpdateTextAsset event, Emitter<DirectorState> emit) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;

      // Find and update the asset in the appropriate layer
      for (int layerIndex = 0; layerIndex < _layers.length; layerIndex++) {
        for (
          int assetIndex = 0;
          assetIndex < _layers[layerIndex].assets.length;
          assetIndex++
        ) {
          if (_layers[layerIndex].assets[assetIndex] ==
              currentState.editingTextAsset) {
            _layers[layerIndex].assets[assetIndex] = event.asset;
            emit(currentState.copyWith(editingTextAsset: event.asset));
            return;
          }
        }
      }
    }
  }

  void _onUpdatePreview(UpdatePreview event, Emitter<DirectorState> emit) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      _updatePlayersPosition(currentState.position);
    }
  }

  bool _checkSomeFileNotExists() {
    for (final layer in _layers) {
      for (final asset in layer.assets) {
        if (asset.srcPath.isNotEmpty && !File(asset.srcPath).existsSync()) {
          asset.deleted = true;
          return true;
        }
      }
    }
    return false;
  }

  int _calculateDuration() {
    if (!_isInitialized) return 0;
    int maxDuration = 0;
    for (int i = 0; i < _layers.length; i++) {
      for (int j = _layers[i].assets.length - 1; j >= 0; j--) {
        if (!(i == 1 && _layers[i].assets[j].title == '')) {
          int dur = _layers[i].assets[j].begin + _layers[i].assets[j].duration;
          maxDuration = math.max(maxDuration, dur);
          break;
        }
      }
    }
    return maxDuration;
  }

  Future<void> _updatePlayersPosition(int position) async {
    for (int i = 0; i < _layerPlayers.length; i++) {
      if (_layerPlayers[i] != null) {
        await _layerPlayers[i]!.preview(position);
      }
    }
  }

  void _startPlayback() {
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (state is DirectorLoaded) {
        final currentState = state as DirectorLoaded;
        final newPosition = currentState.position + 16;

        if (newPosition >= _calculateDuration()) {
          _stopPlayback();
          add(const UpdatePosition(0));
        } else {
          add(UpdatePosition(newPosition));
        }
      }
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
  }

  Asset? getAssetByPosition(int layerIndex) {
    if (!_isInitialized ||
        layerIndex >= _layers.length ||
        state is! DirectorLoaded)
      return null;

    final currentState = state as DirectorLoaded;
    final position = currentState.position;

    for (final asset in _layers[layerIndex].assets) {
      if (position >= asset.begin && position < asset.begin + asset.duration) {
        return asset;
      }
    }

    return null;
  }

  void _onScaleStart(ScaleStart event, Emitter<DirectorState> emit) {
    // Scale start logic can be added here if needed
    // For now, we'll just maintain the current state
  }

  void _onScaleUpdate(ScaleUpdate event, Emitter<DirectorState> emit) {
    if (state is DirectorLoaded) {
      final currentState = state as DirectorLoaded;
      // Update pixelsPerSecond based on scale for zoom effect
      final newPixelsPerSecond = (currentState.pixelsPerSecond * event.scale)
          .clamp(5.0, 100.0);
      emit(currentState.copyWith(pixelsPerSecond: newPixelsPerSecond));
    }
  }

  void _onScaleEnd(ScaleEnd event, Emitter<DirectorState> emit) {
    // Scale end logic can be added here if needed
    // For now, we'll just maintain the current state
  }

  void _onEndScroll(EndScroll event, Emitter<DirectorState> emit) {
    // End scroll logic can be added here if needed
    // For now, we'll just maintain the current state
  }
}
