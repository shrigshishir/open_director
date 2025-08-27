import 'package:equatable/equatable.dart';
import 'package:flutter_video_editor_app/model/project.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjects extends ProjectEvent {}

class RefreshProjects extends ProjectEvent {}

class CreateProject extends ProjectEvent {
  final Project project;

  const CreateProject(this.project);

  @override
  List<Object?> get props => [project];
}

class UpdateProject extends ProjectEvent {
  final Project project;

  const UpdateProject(this.project);

  @override
  List<Object?> get props => [project];
}

class DeleteProject extends ProjectEvent {
  final int projectId;

  const DeleteProject(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class CheckFilesExist extends ProjectEvent {}
