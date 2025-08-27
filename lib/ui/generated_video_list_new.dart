import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/video_generation/video_generation_bloc.dart';
import 'package:flutter_video_editor_app/bloc/video_generation/video_generation_state.dart';
import 'package:flutter_video_editor_app/bloc/video_generation/video_generation_event.dart';
import 'package:flutter_video_editor_app/model/generated_video.dart';
import 'package:flutter_video_editor_app/model/project.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class GeneratedVideoList extends StatefulWidget {
  final Project project;

  const GeneratedVideoList(this.project, {Key? key}) : super(key: key);

  @override
  _GeneratedVideoListState createState() => _GeneratedVideoListState();
}

class _GeneratedVideoListState extends State<GeneratedVideoList> {
  @override
  void initState() {
    super.initState();
    // Load generated videos for this project
    if (widget.project.id != null) {
      context.read<VideoGenerationBloc>().add(
        LoadGeneratedVideos(widget.project.id!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Text('Generated videos', style: TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: BlocBuilder<VideoGenerationBloc, VideoGenerationState>(
              builder: (context, state) {
                if (state is VideoGenerationLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is VideoGenerationLoaded) {
                  final videos = state.videos
                      .where((video) => video.projectId == widget.project.id)
                      .toList();

                  if (videos.isEmpty) {
                    return Center(
                      child: Text(
                        'No generated videos yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: videos.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _GeneratedVideoCard(videos[index]);
                    },
                  );
                } else if (state is VideoGenerationError) {
                  return Center(child: Text('Error: ${state.message}'));
                } else {
                  return Center(child: Text('No videos loaded'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratedVideoCard extends StatelessWidget {
  final GeneratedVideo video;

  const _GeneratedVideoCard(this.video, {Key? key}) : super(key: key);

  messageFileNotExist(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('File does not exist'),
          content: Text('This video file has been deleted from your device'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool fileExists() {
    return File(video.path).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    bool thumbnailExists =
        video.thumbnail != null && File(video.thumbnail!).existsSync();

    return GestureDetector(
      child: Card(
        child: ListTile(
          leading: thumbnailExists ? Image.file(File(video.thumbnail!)) : null,
          title: Text(
            '${DateFormat.yMMMMd().format(video.date)} '
            '${DateFormat.Hm().format(video.date)}',
          ),
          subtitle: Text('${video.resolution}'),
          trailing: PopupMenuButton<int>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (int result) {
              if (result == 1) {
                if (!fileExists()) {
                  messageFileNotExist(context);
                } else {
                  OpenFile.open(video.path);
                }
              } else if (result == 2) {
                if (video.id != null) {
                  context.read<VideoGenerationBloc>().add(
                    DeleteGeneratedVideo(video.id!),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(value: 1, child: Text('Watch')),
              const PopupMenuDivider(height: 10),
              const PopupMenuItem<int>(value: 2, child: Text('Delete')),
            ],
          ),
        ),
      ),
      onTap: () {
        if (!fileExists()) {
          messageFileNotExist(context);
        } else {
          OpenFile.open(video.path);
        }
      },
    );
  }
}
