import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/model/project.dart';
import 'package:flutter_video_editor_app/repository/project_repository.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectRepository _projectRepository;

  ProjectBloc({ProjectRepository? projectRepository})
    : _projectRepository = projectRepository ?? ProjectRepository(),
      super(ProjectInitial()) {
    on<LoadProjects>(_onLoadProjects);
    on<RefreshProjects>(_onRefreshProjects);
    on<CreateProject>(_onCreateProject);
    on<UpdateProject>(_onUpdateProject);
    on<DeleteProject>(_onDeleteProject);
    on<CheckFilesExist>(_onCheckFilesExist);
  }

  Future<void> _onLoadProjects(
    LoadProjects event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      await _projectRepository.initialize();
      final projects = await _projectRepository.getAllProjects();
      _projectRepository.validateProjectFiles(projects);
      emit(ProjectLoaded(projects: projects));
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onRefreshProjects(
    RefreshProjects event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final projects = await _projectRepository.getAllProjects();
      _projectRepository.validateProjectFiles(projects);

      if (state is ProjectLoaded) {
        final currentState = state as ProjectLoaded;
        emit(currentState.copyWith(projects: projects));
      } else {
        emit(ProjectLoaded(projects: projects));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onCreateProject(
    CreateProject event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await _projectRepository.createProject(event.project);
      add(RefreshProjects());
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onUpdateProject(
    UpdateProject event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await _projectRepository.updateProject(event.project);
      add(RefreshProjects());
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onDeleteProject(
    DeleteProject event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await _projectRepository.deleteProject(event.projectId);
      add(RefreshProjects());
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onCheckFilesExist(
    CheckFilesExist event,
    Emitter<ProjectState> emit,
  ) async {
    if (state is ProjectLoaded) {
      final currentState = state as ProjectLoaded;
      final projects = currentState.projects;
      bool hasFilesNotExist = false;

      for (final project in projects) {
        if (project.imagePath != null &&
            !File(project.imagePath!).existsSync()) {
          project.imagePath = null;
          hasFilesNotExist = true;
        }
      }

      if (hasFilesNotExist) {
        emit(currentState.copyWith(projects: projects, hasFilesNotExist: true));
      }
    }
  }

  Project createNew() {
    return _projectRepository.createNewProject();
  }
}
