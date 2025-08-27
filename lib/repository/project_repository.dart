import 'dart:io';
import 'package:flutter_video_editor_app/dao/project_dao.dart';
import 'package:flutter_video_editor_app/model/project.dart';

class ProjectRepository {
  final ProjectDao _projectDao;

  ProjectRepository({ProjectDao? projectDao})
    : _projectDao = projectDao ?? ProjectDao();

  Future<void> initialize() async {
    await _projectDao.open();
  }

  Future<List<Project>> getAllProjects() async {
    return await _projectDao.findAll();
  }

  Future<Project?> getProject(int id) async {
    return await _projectDao.get(id);
  }

  Future<Project> createProject(Project project) async {
    return await _projectDao.insert(project);
  }

  Future<void> updateProject(Project project) async {
    await _projectDao.update(project);
  }

  Future<void> deleteProject(int id) async {
    await _projectDao.delete(id);
  }

  Project createNewProject() {
    return Project(title: '', duration: 0, date: DateTime.now());
  }

  void validateProjectFiles(List<Project> projects) {
    for (final project in projects) {
      if (project.imagePath != null && !File(project.imagePath!).existsSync()) {
        project.imagePath = null;
      }
    }
  }
}
