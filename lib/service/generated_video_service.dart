import 'dart:io';
import 'package:flutter_video_editor_app/dao/project_dao.dart';
import 'package:flutter_video_editor_app/model/generated_video.dart';
import 'package:flutter_video_editor_app/service_locator.dart';
import 'package:rxdart/rxdart.dart';

class GeneratedVideoService {
  final ProjectDao projectDao = locator.get<ProjectDao>();

  List<GeneratedVideo> generatedVideoList = [];
  int? projectId;

  BehaviorSubject<bool> _generatedVideoListChanged = BehaviorSubject.seeded(
    false,
  );
  // Observable<bool> get generatedVideoListChanged$ =>
  //     _generatedVideoListChanged.stream;
  bool get generatedVideoListChanged => _generatedVideoListChanged.value;

  GeneratedVideoService() {
    open();
  }

  dispose() {
    _generatedVideoListChanged.close();
  }

  void open() async {
    await projectDao.open();
  }

  Stream<bool> get generatedVideoListChanged$ =>
      _generatedVideoListChanged.stream;

  void refresh(int projectId) async {
    projectId = projectId;
    generatedVideoList = [];
    _generatedVideoListChanged.add(true);
    generatedVideoList = await projectDao.findAllGeneratedVideo(projectId);
    _generatedVideoListChanged.add(true);
  }

  fileExists(index) {
    return File(generatedVideoList[index].path).existsSync();
  }

  delete(index) async {
    if (fileExists(index)) File(generatedVideoList[index].path).deleteSync();
    if (generatedVideoList[index].id == null) {
      print("Generated video id is null. Cannot delete generated video.");
      return;
    }
    await projectDao.deleteGeneratedVideo(generatedVideoList[index].id!);
    refresh(projectId!);
  }
}
