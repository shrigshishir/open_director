import 'package:equatable/equatable.dart';
import 'package:flutter_video_editor_app/model/generated_video.dart';

abstract class VideoGenerationState extends Equatable {
  const VideoGenerationState();

  @override
  List<Object?> get props => [];
}

class VideoGenerationInitial extends VideoGenerationState {}

class VideoGenerationLoading extends VideoGenerationState {}

class VideoGenerationLoaded extends VideoGenerationState {
  final List<GeneratedVideo> videos;
  final int? projectId;

  const VideoGenerationLoaded({required this.videos, this.projectId});

  @override
  List<Object?> get props => [videos, projectId];

  VideoGenerationLoaded copyWith({
    List<GeneratedVideo>? videos,
    int? projectId,
  }) {
    return VideoGenerationLoaded(
      videos: videos ?? this.videos,
      projectId: projectId ?? this.projectId,
    );
  }
}

class VideoGenerationError extends VideoGenerationState {
  final String message;

  const VideoGenerationError(this.message);

  @override
  List<Object?> get props => [message];
}
