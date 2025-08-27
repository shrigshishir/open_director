import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/model/project.dart';

abstract class DirectorState extends Equatable {
  const DirectorState();

  @override
  List<Object?> get props => [];
}

class DirectorInitial extends DirectorState {}

class DirectorLoading extends DirectorState {}

class DirectorLoaded extends DirectorState {
  final Project project;
  final List<Layer> layers;
  final int position;
  final bool isPlaying;
  final int selectedLayerIndex;
  final int selectedAssetIndex;
  final double pixelsPerSecond;
  final Asset? editingTextAsset;
  final String? editingColorType;
  final ScrollController scrollController;
  final bool filesNotExist;

  const DirectorLoaded({
    required this.project,
    required this.layers,
    this.position = 0,
    this.isPlaying = false,
    this.selectedLayerIndex = -1,
    this.selectedAssetIndex = -1,
    this.pixelsPerSecond = 20.0,
    this.editingTextAsset,
    this.editingColorType,
    required this.scrollController,
    this.filesNotExist = false,
  });

  bool get editingColor =>
      editingColorType != null && editingColorType!.isNotEmpty;

  @override
  List<Object?> get props => [
    project,
    layers,
    position,
    isPlaying,
    selectedLayerIndex,
    selectedAssetIndex,
    pixelsPerSecond,
    editingTextAsset,
    editingColorType,
    filesNotExist,
  ];

  DirectorLoaded copyWith({
    Project? project,
    List<Layer>? layers,
    int? position,
    bool? isPlaying,
    int? selectedLayerIndex,
    int? selectedAssetIndex,
    double? pixelsPerSecond,
    Asset? editingTextAsset,
    String? editingColorType,
    ScrollController? scrollController,
    bool? filesNotExist,
    bool clearEditingTextAsset = false,
    bool clearEditingColorType = false,
  }) {
    return DirectorLoaded(
      project: project ?? this.project,
      layers: layers ?? this.layers,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      selectedLayerIndex: selectedLayerIndex ?? this.selectedLayerIndex,
      selectedAssetIndex: selectedAssetIndex ?? this.selectedAssetIndex,
      pixelsPerSecond: pixelsPerSecond ?? this.pixelsPerSecond,
      editingTextAsset: clearEditingTextAsset
          ? null
          : (editingTextAsset ?? this.editingTextAsset),
      editingColorType: clearEditingColorType
          ? null
          : (editingColorType ?? this.editingColorType),
      scrollController: scrollController ?? this.scrollController,
      filesNotExist: filesNotExist ?? this.filesNotExist,
    );
  }

  int get duration => project.duration;

  String get positionMinutes {
    final minutes = (position / 60000).floor();
    return minutes < 10 ? '0$minutes' : '$minutes';
  }

  String get positionSeconds {
    final totalSeconds = (position / 1000).floor();
    final seconds = totalSeconds % 60;
    return seconds < 10 ? '0$seconds' : '$seconds';
  }
}

class DirectorError extends DirectorState {
  final String message;

  const DirectorError(this.message);

  @override
  List<Object?> get props => [message];
}
