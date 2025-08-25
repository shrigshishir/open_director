import 'dart:io';
import 'package:flutter_video_editor_app/dao/project_dao.dart';
import 'package:flutter_video_editor_app/model/project.dart';
import 'package:flutter_video_editor_app/service_locator.dart';
import 'package:rxdart/rxdart.dart';

class ProjectService {
  final ProjectDao projectDao = locator.get<ProjectDao>();

  List<Project> projectList = [];
  Project? project;

  BehaviorSubject<bool> _projectListChanged = BehaviorSubject.seeded(false);
  // Observable<bool> get projectListChanged$ => _projectListChanged.stream;
  bool get projectListChanged => _projectListChanged.value;

  ProjectService() {
    load();
  }

  dispose() {
    _projectListChanged.close();
  }

  Stream<bool> get projectListChanged$ => _projectListChanged.stream;

  void load() async {
    await projectDao.open();
    refresh();
  }

  void refresh() async {
    projectList = await projectDao.findAll();
    _projectListChanged.add(true);
    checkSomeFileNotExists();
  }

  checkSomeFileNotExists() {
    for (int i = 0; i < projectList.length; i++) {
      if (projectList[i].imagePath != null &&
          !File(projectList[i].imagePath!).existsSync()) {
        print('${projectList[i].imagePath} does not exists');
        projectList[i].imagePath = null;
      }
    }
  }

  Project createNew() {
    return Project(title: '', duration: 0, date: DateTime.now());
  }

  insert(project) async {
    final updatedProject = project.copyWith(date: DateTime.now());
    await projectDao.insert(updatedProject);
    refresh();
  }

  update(project) async {
    await projectDao.update(project);
    refresh();
  }

  delete(index) async {
    if (projectList[index].id == null) {
      print("Project id is null. Cannot delete project.");
      return;
    }
    await projectDao.delete(projectList[index].id!);
    refresh();
  }
}
