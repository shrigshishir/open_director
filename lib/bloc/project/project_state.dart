import 'package:equatable/equatable.dart';
import 'package:flutter_video_editor_app/model/project.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectLoaded extends ProjectState {
  final List<Project> projects;
  final bool hasFilesNotExist;

  const ProjectLoaded({required this.projects, this.hasFilesNotExist = false});

  @override
  List<Object?> get props => [projects, hasFilesNotExist];

  ProjectLoaded copyWith({List<Project>? projects, bool? hasFilesNotExist}) {
    return ProjectLoaded(
      projects: projects ?? this.projects,
      hasFilesNotExist: hasFilesNotExist ?? this.hasFilesNotExist,
    );
  }
}

class ProjectError extends ProjectState {
  final String message;

  const ProjectError(this.message);

  @override
  List<Object?> get props => [message];
}
