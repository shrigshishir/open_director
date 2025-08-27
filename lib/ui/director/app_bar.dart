import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_state.dart';
import 'package:flutter_video_editor_app/bloc/director/director_event.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/ui/director/params.dart';
import 'package:flutter_video_editor_app/ui/generated_video_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class AppBar1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        bool isLandscape =
            (MediaQuery.of(context).orientation == Orientation.landscape);
        if (state is DirectorLoaded) {
          if (state.editingTextAsset == null) {
            if (isLandscape) {
              return _AppBar1Landscape();
            } else {
              return _AppBar1Portrait();
            }
          } else if (state.editingColorType == null) {
            if (isLandscape) {
              return Container(width: Params.getSideMenuWidth(context));
            } else {
              return _AppBar1Portrait();
            }
          } else {
            if (isLandscape) {
              return Container(width: Params.getSideMenuWidth(context));
            } else {
              return _AppBar1Portrait();
            }
          }
        }
        return Container();
      },
    );
  }
}

class AppBar2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        bool isLandscape =
            (MediaQuery.of(context).orientation == Orientation.landscape);
        if (state is DirectorLoaded) {
          if (state.editingTextAsset == null) {
            if (isLandscape) {
              return _AppBar2Landscape();
            } else {
              return _AppBar2Portrait();
            }
          } else if (state.editingColorType == null) {
            if (isLandscape) {
              return _AppBar2EditingTextLandscape();
            } else {
              return _AppBar2EditingTextPortrait();
            }
          } else {
            if (isLandscape) {
              return Container(width: Params.getSideMenuWidth(context));
            } else {
              return Container();
            }
          }
        }
        return Container();
      },
    );
  }
}

class _AppBar1Landscape extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        List<Widget> children = [];
        children.add(_ButtonBack());

        if (state is DirectorLoaded) {
          if (state.selectedLayerIndex != -1) {
            children.add(_ButtonDelete());
          } else {
            children.add(Container(height: 48));
          }

          Asset? selectedAsset;
          if (state.selectedLayerIndex != -1 &&
              state.selectedAssetIndex != -1 &&
              state.selectedLayerIndex < state.layers.length &&
              state.selectedAssetIndex <
                  state.layers[state.selectedLayerIndex].assets.length) {
            selectedAsset = state
                .layers[state.selectedLayerIndex]
                .assets[state.selectedAssetIndex];
          }

          if (selectedAsset?.type == AssetType.video ||
              selectedAsset?.type == AssetType.audio) {
            children.add(_ButtonCut());
          } else if (selectedAsset?.type == AssetType.text) {
            children.add(_ButtonEdit());
          } else {
            children.add(Container(height: 48));
          }
        }

        return Container(
          width: Params.getSideMenuWidth(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        );
      },
    );
  }
}

class _AppBar1Portrait extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        List<Widget> children = [];
        children.add(_ButtonBack());
        return AppBar(
          leading: _ButtonBack(),
          title: Text(
            state is DirectorLoaded ? state.project.title : "Untitled Project",
          ),
          actions: children,
        );
      },
    );
  }
}

class _AppBar2Landscape extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        List<Widget> children = [];
        children.add(_ButtonAdd());

        if (state is DirectorLoaded) {
          if (state.layers.isNotEmpty &&
              state.layers[0].assets.isNotEmpty &&
              !state.isPlaying) {
            children.add(_ButtonPlay());
          }
          if (state.isPlaying) {
            children.add(_ButtonPause());
          }
          if (state.layers.isNotEmpty && state.layers[0].assets.isNotEmpty) {
            children.add(_ButtonGenerate());
          }
        }

        return Container(
          width: Params.getSideMenuWidth(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          ),
        );
      },
    );
  }
}

class _AppBar2Portrait extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        List<Widget> children = [];
        children.add(_ButtonAdd());

        if (state is DirectorLoaded) {
          if (state.layers.isNotEmpty &&
              state.layers[0].assets.isNotEmpty &&
              !state.isPlaying) {
            children.add(_ButtonPlay());
          }
          if (state.isPlaying) {
            children.add(_ButtonPause());
          }
          if (state.layers.isNotEmpty && state.layers[0].assets.isNotEmpty) {
            children.add(_ButtonGenerate());
          }

          List<Widget> children2 = [];
          if (state.selectedLayerIndex != -1) {
            children2.add(_ButtonDelete());
          }

          Asset? selectedAsset;
          if (state.selectedLayerIndex != -1 &&
              state.selectedAssetIndex != -1 &&
              state.selectedLayerIndex < state.layers.length &&
              state.selectedAssetIndex <
                  state.layers[state.selectedLayerIndex].assets.length) {
            selectedAsset = state
                .layers[state.selectedLayerIndex]
                .assets[state.selectedAssetIndex];
          }

          if (selectedAsset?.type == AssetType.video ||
              selectedAsset?.type == AssetType.audio) {
            children2.add(_ButtonCut());
          } else if (selectedAsset?.type == AssetType.text) {
            children2.add(_ButtonEdit());
          }

          return Container(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: children2),
                Row(children: children),
              ],
            ),
          );
        }

        return Container();
      },
    );
  }
}

class _AppBar2EditingTextLandscape extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        return Container(
          width: Params.getSideMenuWidth(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                child: Text('SAVE'),
                onPressed: () {
                  if (state is DirectorLoaded &&
                      state.editingTextAsset != null) {
                    context.read<DirectorBloc>().add(
                      UpdateTextAsset(state.editingTextAsset!),
                    );
                    context.read<DirectorBloc>().add(StopEditingTextAsset());
                  }
                },
              ),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  context.read<DirectorBloc>().add(StopEditingTextAsset());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppBar2EditingTextPortrait extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        List<Widget> children = [];
        children.add(_ButtonAdd());

        return Container(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                child: Text('SAVE'),
                onPressed: () {
                  if (state is DirectorLoaded &&
                      state.editingTextAsset != null) {
                    context.read<DirectorBloc>().add(
                      UpdateTextAsset(state.editingTextAsset!),
                    );
                    context.read<DirectorBloc>().add(StopEditingTextAsset());
                  }
                },
              ),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  context.read<DirectorBloc>().add(StopEditingTextAsset());
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ButtonBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.grey.shade500),
      tooltip: "Back",
      onPressed: () async {
        context.read<DirectorBloc>().add(SaveProject());
        Navigator.pop(context);
      },
    );
  }
}

class _ButtonDelete extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        return FloatingActionButton(
          heroTag: "delete",
          tooltip: "Delete selected",
          backgroundColor: Colors.pink,
          mini: MediaQuery.of(context).size.width < 900,
          child: Icon(Icons.delete, color: Colors.white),
          onPressed: () {
            if (state is DirectorLoaded &&
                state.selectedLayerIndex != -1 &&
                state.selectedAssetIndex != -1) {
              context.read<DirectorBloc>().add(
                RemoveAsset(state.selectedLayerIndex, state.selectedAssetIndex),
              );
            }
          },
        );
      },
    );
  }
}

class _ButtonCut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "cut",
      tooltip: "Cut video selected",
      backgroundColor: Colors.blue,
      mini: MediaQuery.of(context).size.width < 900,
      child: Icon(Icons.content_cut, color: Colors.white),
      onPressed: () {
        // TODO: Implement cut functionality with BLoC
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cut functionality will be implemented')),
        );
      },
    );
  }
}

class _ButtonEdit extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        return FloatingActionButton(
          heroTag: "edit",
          tooltip: "Edit",
          backgroundColor: Colors.blue,
          mini: MediaQuery.of(context).size.width < 900,
          child: Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            if (state is DirectorLoaded) {
              Asset? selectedAsset;
              if (state.selectedLayerIndex != -1 &&
                  state.selectedAssetIndex != -1 &&
                  state.selectedLayerIndex < state.layers.length &&
                  state.selectedAssetIndex <
                      state.layers[state.selectedLayerIndex].assets.length) {
                selectedAsset = state
                    .layers[state.selectedLayerIndex]
                    .assets[state.selectedAssetIndex];
              }
              if (selectedAsset != null) {
                context.read<DirectorBloc>().add(
                  StartEditingTextAsset(selectedAsset),
                );
              }
            }
          },
        );
      },
    );
  }
}

class _ButtonAdd extends StatelessWidget {
  Future<void> _pickAndAddAsset(
    BuildContext context,
    AssetType assetType,
  ) async {
    try {
      FilePickerResult? result;

      switch (assetType) {
        case AssetType.video:
          result = await FilePicker.platform.pickFiles(
            type: FileType.video,
            allowMultiple: false,
          );
          break;
        case AssetType.image:
          result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
          );
          break;
        case AssetType.audio:
          result = await FilePicker.platform.pickFiles(
            type: FileType.audio,
            allowMultiple: false,
          );
          break;
        case AssetType.text:
          // For text assets, we'll create a default text asset
          _createTextAsset(context);
          return;
      }

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final filePath = file.path!;
        final fileName = path.basenameWithoutExtension(file.name);

        // Create asset based on type
        Asset newAsset = Asset(
          type: assetType,
          srcPath: filePath,
          title: fileName,
          duration: assetType == AssetType.image
              ? 5000
              : 10000, // Default durations in ms
          begin: 0,
        );

        // Add asset to the first layer (index 0)
        if (context.mounted) {
          context.read<DirectorBloc>().add(AddAsset(0, newAsset));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${assetType.name}: $fileName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createTextAsset(BuildContext context) {
    // Create a default text asset
    Asset textAsset = Asset(
      type: AssetType.text,
      srcPath: '',
      title: 'New Text',
      duration: 5000, // 5 seconds default
      begin: 0,
    );

    context.read<DirectorBloc>().add(AddAsset(0, textAsset));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added text asset'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "add",
      tooltip: "Add media",
      backgroundColor: Colors.blue,
      mini: MediaQuery.of(context).size.width < 900,
      onPressed: () {
        print("called");
      },
      child: PopupMenuButton<AssetType>(
        icon: Icon(Icons.add, color: Colors.white),
        onSelected: (AssetType result) {
          _pickAndAddAsset(context, result);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<AssetType>>[
          const PopupMenuItem<AssetType>(
            value: AssetType.video,
            child: Text('Add video'),
          ),
          const PopupMenuItem<AssetType>(
            value: AssetType.image,
            child: Text('Add image'),
          ),
          const PopupMenuItem<AssetType>(
            value: AssetType.audio,
            child: Text('Add audio'),
          ),
          const PopupMenuItem<AssetType>(
            value: AssetType.text,
            child: Text('Add title'),
          ),
        ],
      ),
    );
  }
}

class _ButtonPlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "play",
      tooltip: "Play",
      backgroundColor: Colors.blue,
      mini: MediaQuery.of(context).size.width < 900,
      child: Icon(Icons.play_arrow, color: Colors.white),
      onPressed: () {
        context.read<DirectorBloc>().add(PlayPause());
      },
    );
  }
}

class _ButtonPause extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "pause",
      tooltip: "Pause",
      backgroundColor: Colors.blue,
      mini: MediaQuery.of(context).size.width < 900,
      child: Icon(Icons.pause, color: Colors.white),
      onPressed: () {
        context.read<DirectorBloc>().add(PlayPause());
      },
    );
  }
}

enum VideoResolution { fullHd, hd, sd }

class _ButtonGenerate extends StatelessWidget {
  showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Generating Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Please wait while your video is being generated...'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        return FloatingActionButton(
          heroTag: "generate",
          tooltip: "Generate video",
          backgroundColor: Colors.blue,
          mini: MediaQuery.of(context).size.width < 900,
          onPressed: () {},
          child: PopupMenuButton<dynamic>(
            icon: Icon(Icons.theaters, color: Colors.white),
            onSelected: (dynamic val) {
              if (state is DirectorLoaded) {
                if (val == 99) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GeneratedVideoList(state.project),
                    ),
                  );
                } else {
                  // TODO: Implement video generation with BLoC
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Video generation will be implemented'),
                    ),
                  );
                  showProgressDialog(context);
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<dynamic>>[
              const PopupMenuItem<VideoResolution>(
                value: VideoResolution.fullHd,
                child: Text('Generate Full HD 1080px'),
              ),
              const PopupMenuItem<VideoResolution>(
                value: VideoResolution.hd,
                child: Text('Generate HD 720px'),
              ),
              const PopupMenuItem<VideoResolution>(
                value: VideoResolution.sd,
                child: Text('Generate SD 360px'),
              ),
              const PopupMenuDivider(height: 10),
              const PopupMenuItem<int>(
                value: 99,
                child: Text('View generated videos'),
              ),
            ],
          ),
        );
      },
    );
  }
}
