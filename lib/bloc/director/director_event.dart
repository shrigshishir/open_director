import 'package:equatable/equatable.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/model/project.dart';

abstract class DirectorEvent extends Equatable {
  const DirectorEvent();

  @override
  List<Object?> get props => [];
}

class InitializeDirector extends DirectorEvent {
  final Project project;

  const InitializeDirector(this.project);

  @override
  List<Object?> get props => [project];
}

class UpdatePosition extends DirectorEvent {
  final int position;

  const UpdatePosition(this.position);

  @override
  List<Object?> get props => [position];
}

class PlayPause extends DirectorEvent {}

class SelectAsset extends DirectorEvent {
  final int layerIndex;
  final int assetIndex;

  const SelectAsset(this.layerIndex, this.assetIndex);

  @override
  List<Object?> get props => [layerIndex, assetIndex];
}

class ScaleTimeline extends DirectorEvent {
  final double scale;

  const ScaleTimeline(this.scale);

  @override
  List<Object?> get props => [scale];
}

class DragAsset extends DirectorEvent {
  final int layerIndex;
  final int assetIndex;
  final double deltaX;

  const DragAsset(this.layerIndex, this.assetIndex, this.deltaX);

  @override
  List<Object?> get props => [layerIndex, assetIndex, deltaX];
}

class AddAsset extends DirectorEvent {
  final int layerIndex;
  final Asset asset;

  const AddAsset(this.layerIndex, this.asset);

  @override
  List<Object?> get props => [layerIndex, asset];
}

class RemoveAsset extends DirectorEvent {
  final int layerIndex;
  final int assetIndex;

  const RemoveAsset(this.layerIndex, this.assetIndex);

  @override
  List<Object?> get props => [layerIndex, assetIndex];
}

class SaveProject extends DirectorEvent {}

class StartEditingTextAsset extends DirectorEvent {
  final Asset asset;

  const StartEditingTextAsset(this.asset);

  @override
  List<Object?> get props => [asset];
}

class StopEditingTextAsset extends DirectorEvent {}

class StartEditingColor extends DirectorEvent {
  final String colorType;

  const StartEditingColor(this.colorType);

  @override
  List<Object?> get props => [colorType];
}

class StopEditingColor extends DirectorEvent {}

class UpdateTextAsset extends DirectorEvent {
  final Asset asset;

  const UpdateTextAsset(this.asset);

  @override
  List<Object?> get props => [asset];
}

class UpdatePreview extends DirectorEvent {}

class ScaleStart extends DirectorEvent {
  const ScaleStart();
}

class ScaleUpdate extends DirectorEvent {
  final double scale;

  const ScaleUpdate(this.scale);

  @override
  List<Object?> get props => [scale];
}

class ScaleEnd extends DirectorEvent {
  const ScaleEnd();
}

class EndScroll extends DirectorEvent {
  const EndScroll();
}
