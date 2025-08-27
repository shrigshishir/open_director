import 'package:equatable/equatable.dart';
import 'package:flutter_video_editor_app/model/generated_video.dart';

abstract class VideoGenerationEvent extends Equatable {
  const VideoGenerationEvent();

  @override
  List<Object?> get props => [];
}

class LoadGeneratedVideos extends VideoGenerationEvent {
  final int projectId;

  const LoadGeneratedVideos(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class RefreshGeneratedVideos extends VideoGenerationEvent {}

class AddGeneratedVideo extends VideoGenerationEvent {
  final GeneratedVideo video;

  const AddGeneratedVideo(this.video);

  @override
  List<Object?> get props => [video];
}

class DeleteGeneratedVideo extends VideoGenerationEvent {
  final int videoId;

  const DeleteGeneratedVideo(this.videoId);

  @override
  List<Object?> get props => [videoId];
}
