// Temporary simplified director screen to allow compilation
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_event.dart';
import 'package:flutter_video_editor_app/bloc/director/director_state.dart';
import 'package:flutter_video_editor_app/model/project.dart';
import 'package:flutter_video_editor_app/repository/project_repository.dart';

class DirectorScreen extends StatelessWidget {
  final Project project;

  const DirectorScreen(this.project, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DirectorBloc>(
      create: (context) =>
          DirectorBloc(projectRepository: context.read<ProjectRepository>())
            ..add(InitializeDirector(project)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.title),
          backgroundColor: Colors.grey.shade900,
        ),
        backgroundColor: Colors.grey.shade900,
        body: BlocBuilder<DirectorBloc, DirectorState>(
          builder: (context, state) {
            if (state is DirectorLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DirectorError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            if (state is DirectorLoaded) {
              return Column(
                children: [
                  // Video preview area
                  Container(
                    height: 200,
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        'Video Preview Area',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  // Timeline area
                  Expanded(
                    child: Container(
                      color: Colors.grey.shade800,
                      child: Column(
                        children: [
                          // Position info
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'Position: ${state.positionMinutes}:${state.positionSeconds}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          // Simplified timeline
                          Expanded(
                            child: ListView.builder(
                              itemCount: state.layers.length,
                              itemBuilder: (context, index) {
                                final layer = state.layers[index];
                                return Container(
                                  height: 60,
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade700,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        layer.type == "raster"
                                            ? Icons.photo
                                            : layer.type == "vector"
                                            ? Icons.text_fields
                                            : Icons.music_note,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${layer.type} (${layer.assets.length} assets)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          // Control buttons
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () => context
                                      .read<DirectorBloc>()
                                      .add(PlayPause()),
                                  child: Icon(
                                    state.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => context
                                      .read<DirectorBloc>()
                                      .add(SaveProject()),
                                  child: const Icon(Icons.save),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return const Center(
              child: Text(
                'Initializing...',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}
