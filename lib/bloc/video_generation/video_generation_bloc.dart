import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/dao/project_dao.dart';
import 'package:flutter_video_editor_app/model/generated_video.dart';
import 'package:flutter_video_editor_app/service/video_generation_service.dart';
import 'video_generation_event.dart';
import 'video_generation_state.dart';

class VideoGenerationBloc
    extends Bloc<VideoGenerationEvent, VideoGenerationState> {
  final ProjectDao _projectDao;
  final VideoGenerationService _videoService;

  VideoGenerationBloc({
    ProjectDao? projectDao,
    VideoGenerationService? videoService,
  }) : _projectDao = projectDao ?? ProjectDao(),
       _videoService = videoService ?? VideoGenerationService(),
       super(VideoGenerationInitial()) {
    on<LoadGeneratedVideos>(_onLoadGeneratedVideos);
    on<RefreshGeneratedVideos>(_onRefreshGeneratedVideos);
    on<AddGeneratedVideo>(_onAddGeneratedVideo);
    on<DeleteGeneratedVideo>(_onDeleteGeneratedVideo);
  }

  Future<void> _onLoadGeneratedVideos(
    LoadGeneratedVideos event,
    Emitter<VideoGenerationState> emit,
  ) async {
    try {
      emit(VideoGenerationLoading());
      await _projectDao.open();
      final videos = await _projectDao.findAllGeneratedVideo(event.projectId);
      emit(VideoGenerationLoaded(videos: videos, projectId: event.projectId));
    } catch (e) {
      emit(VideoGenerationError(e.toString()));
    }
  }

  Future<void> _onRefreshGeneratedVideos(
    RefreshGeneratedVideos event,
    Emitter<VideoGenerationState> emit,
  ) async {
    if (state is VideoGenerationLoaded) {
      final currentState = state as VideoGenerationLoaded;
      if (currentState.projectId != null) {
        try {
          final videos = await _projectDao.findAllGeneratedVideo(
            currentState.projectId!,
          );
          emit(currentState.copyWith(videos: videos));
        } catch (e) {
          emit(VideoGenerationError(e.toString()));
        }
      }
    }
  }

  Future<void> _onAddGeneratedVideo(
    AddGeneratedVideo event,
    Emitter<VideoGenerationState> emit,
  ) async {
    try {
      await _projectDao.insertGeneratedVideo(event.video);
      add(RefreshGeneratedVideos());
    } catch (e) {
      emit(VideoGenerationError(e.toString()));
    }
  }

  Future<void> _onDeleteGeneratedVideo(
    DeleteGeneratedVideo event,
    Emitter<VideoGenerationState> emit,
  ) async {
    try {
      await _projectDao.deleteGeneratedVideo(event.videoId);
      add(RefreshGeneratedVideos());
    } catch (e) {
      emit(VideoGenerationError(e.toString()));
    }
  }
}
