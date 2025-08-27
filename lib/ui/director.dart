import 'dart:core';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_event.dart';
import 'package:flutter_video_editor_app/bloc/director/director_state.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/model/project.dart';
import 'package:flutter_video_editor_app/repository/project_repository.dart';
import 'package:flutter_video_editor_app/ui/common/animated_dialog.dart';
import 'package:flutter_video_editor_app/ui/director/asset_selection.dart';
import 'package:flutter_video_editor_app/ui/director/color_editor.dart';
import 'package:flutter_video_editor_app/ui/director/drag_closest.dart';
import 'package:flutter_video_editor_app/ui/director/params.dart';
import 'package:flutter_video_editor_app/ui/director/text_asset_editor.dart';
import 'dart:async';

class DirectorScreen extends StatelessWidget {
  final Project project;

  const DirectorScreen(this.project, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DirectorBloc>(
      create: (context) =>
          DirectorBloc(projectRepository: context.read<ProjectRepository>())
            ..add(InitializeDirector(project)),
      child: const _DirectorScreenContent(),
    );
  }
}

class _DirectorScreenContent extends StatefulWidget {
  const _DirectorScreenContent({Key? key}) : super(key: key);

  @override
  State<_DirectorScreenContent> createState() => _DirectorScreenContentState();
}

class _DirectorScreenContentState extends State<_DirectorScreenContent>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      Params.fixHeight = true;
    } else if (state == AppLifecycleState.resumed) {
      Params.fixHeight = false;
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // To release memory
    imageCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DirectorBloc, DirectorState>(
      listener: (context, state) {
        if (state is DirectorLoaded && state.filesNotExist) {
          // Delayed because widgets are building
          Future.delayed(const Duration(milliseconds: 100), () {
            AnimatedDialog.show(
              context,
              title: 'Some assets have been deleted',
              child: const Text(
                'To continue you must recover deleted assets in your device '
                'or remove them from the timeline (marked in red).',
              ),
              button2Text: 'OK',
              onPressedButton2: () {
                Navigator.of(context).pop();
              },
            );
          });
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          final bloc = context.read<DirectorBloc>();
          final state = bloc.state;

          if (state is DirectorLoaded) {
            if (state.editingColor) {
              bloc.add(StopEditingColor());
              return false;
            }
            if (state.editingTextAsset != null) {
              bloc.add(StopEditingTextAsset());
              return false;
            }

            bloc.add(SaveProject());
            Navigator.pop(context);
          }
          return false;
        },
        child: Material(
          color: Colors.grey.shade900,
          child: SafeArea(
            child: GestureDetector(
              onTap: () {
                final bloc = context.read<DirectorBloc>();
                final state = bloc.state;
                if (state is DirectorLoaded && state.editingTextAsset == null) {
                  bloc.add(const SelectAsset(-1, -1));
                }
                // Hide keyboard
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: Container(
                color: Colors.grey.shade900,
                child: const _Director(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Director extends StatelessWidget {
  const _Director({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height:
              Params.getPlayerHeight(context) +
              (MediaQuery.of(context).orientation == Orientation.landscape
                  ? 0
                  : Params.APP_BAR_HEIGHT * 2),
          child: MediaQuery.of(context).orientation == Orientation.landscape
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const AppBar1(),
                    const _Video(),
                    const AppBar2(),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const AppBar1(),
                    const _Video(),
                    const AppBar2(),
                  ],
                ),
        ),
        Expanded(
          child: Container(
            child: Stack(
              alignment: const Alignment(0, -1),
              children: <Widget>[
                SingleChildScrollView(
                  child: Stack(
                    alignment: const Alignment(-1, -1),
                    children: <Widget>[
                      GestureDetector(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollState) {
                            if (scrollState is ScrollEndNotification) {
                              context.read<DirectorBloc>().add(
                                const EndScroll(),
                              );
                            }
                            return false;
                          },
                          child: const _TimeLine(),
                        ),
                        onScaleStart: (ScaleStartDetails details) {
                          context.read<DirectorBloc>().add(const ScaleStart());
                        },
                        onScaleUpdate: (ScaleUpdateDetails details) {
                          context.read<DirectorBloc>().add(
                            ScaleUpdate(details.horizontalScale),
                          );
                        },
                        onScaleEnd: (ScaleEndDetails details) {
                          context.read<DirectorBloc>().add(const ScaleEnd());
                        },
                      ),
                      const _LayerHeaders(),
                    ],
                  ),
                ),
                const _PositionLine(),
                const _PositionMarker(),
                TextAssetEditor(),
                ColorEditor(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PositionLine extends StatelessWidget {
  const _PositionLine({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: Params.getTimelineHeight(context) - 4,
      margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      color: Colors.grey.shade100,
    );
  }
}

class _PositionMarker extends StatelessWidget {
  const _PositionMarker({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: Params.RULER_HEIGHT - 4,
      margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      color: Colors.blue,
      child: BlocBuilder<DirectorBloc, DirectorState>(
        builder: (context, state) {
          if (state is! DirectorLoaded) {
            return const Center(
              child: Text(
                '00:00',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            );
          }

          return Center(
            child: Text(
              '${state.positionMinutes}:${state.positionSeconds}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}

class _TimeLine extends StatelessWidget {
  const _TimeLine({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded) {
          return const SizedBox.shrink();
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: state.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Ruler(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: state.layers
                    .asMap()
                    .map((index, layer) => MapEntry(index, _LayerAssets(index)))
                    .values
                    .toList(),
              ),
              Container(height: Params.getLayerBottom(context)),
            ],
          ),
        );
      },
    );
  }
}

class _Ruler extends StatelessWidget {
  const _Ruler({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded) {
          return const SizedBox.shrink();
        }

        return CustomPaint(
          painter: RulerPainter(
            context,
            pixelsPerSecond: state.pixelsPerSecond,
            duration: state.duration,
          ),
          child: Container(
            height: Params.RULER_HEIGHT - 4,
            width:
                MediaQuery.of(context).size.width +
                state.pixelsPerSecond * state.duration / 1000,
            margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
          ),
        );
      },
    );
  }
}

class RulerPainter extends CustomPainter {
  final BuildContext context;
  final double pixelsPerSecond;
  final int duration;

  RulerPainter(
    this.context, {
    required this.pixelsPerSecond,
    required this.duration,
  });

  getSecondsPerDivision(double pixPerSec) {
    if (pixPerSec > 40) {
      return 1;
    } else if (pixPerSec > 20) {
      return 2;
    } else if (pixPerSec > 10) {
      return 5;
    } else if (pixPerSec > 4) {
      return 10;
    } else if (pixPerSec > 1.5) {
      return 30;
    } else {
      return 60;
    }
  }

  getTimeText(int seconds) {
    return '${(seconds / 60).floor() < 10 ? '0' : ''}'
        '${(seconds / 60).floor()}'
        '.${seconds - (seconds / 60).floor() * 60 < 10 ? '0' : ''}'
        '${seconds - (seconds / 60).floor() * 60}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double width =
        duration / 1000 * pixelsPerSecond + MediaQuery.of(context).size.width;

    final paint = Paint();
    paint.color = Colors.grey.shade800;
    Rect rect = Rect.fromLTWH(0, 2, width, size.height - 4);
    canvas.drawRect(rect, paint);

    paint.color = Colors.grey.shade400;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;

    Path path = Path();
    path.moveTo(0, size.height - 2);
    path.relativeLineTo(width, 0);
    path.close();
    canvas.drawPath(path, paint);

    int secondsPerDivision = getSecondsPerDivision(pixelsPerSecond);
    final double pixelsPerDivision = secondsPerDivision * pixelsPerSecond;
    final int numberOfDivisions =
        ((width - MediaQuery.of(context).size.width / 2) / pixelsPerDivision)
            .floor();

    for (int i = 0; i <= numberOfDivisions; i++) {
      int seconds = i * secondsPerDivision;
      String text = getTimeText(seconds);

      final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        text: TextSpan(
          text: text,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
        ),
      );

      textPainter.layout();
      double x = MediaQuery.of(context).size.width / 2 + i * pixelsPerDivision;
      textPainter.paint(canvas, Offset(x + 6, 6));

      Path path = Path();
      path.moveTo(x + 1, size.height - 4);
      path.relativeLineTo(0, -8);
      path.moveTo(x + 1 + 0.5 * pixelsPerDivision, size.height - 4);
      path.relativeLineTo(0, -2);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _LayerHeaders extends StatelessWidget {
  const _LayerHeaders({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: Params.RULER_HEIGHT),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: state.layers
                  .asMap()
                  .map(
                    (index, layer) => MapEntry(index, _LayerHeader(layer.type)),
                  )
                  .values
                  .toList(),
            ),
            Container(height: Params.getLayerBottom(context)),
          ],
        );
      },
    );
  }
}

class _Video extends StatelessWidget {
  const _Video({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded) {
          return Container(
            color: Colors.black,
            height: Params.getPlayerHeight(context),
            width: Params.getPlayerWidth(context),
          );
        }

        var backgroundContainer = Container(
          color: Colors.black,
          height: Params.getPlayerHeight(context),
          width: Params.getPlayerWidth(context),
        );

        // TODO: Implement video player logic with BLoC
        return Container(
          height: Params.getPlayerHeight(context),
          width: Params.getPlayerWidth(context),
          child: Stack(
            children: [
              backgroundContainer,
              // TODO: Add video player widgets here
            ],
          ),
        );
      },
    );
  }
}

class KenBurnEffect extends StatelessWidget {
  final String path;
  final double ratio;
  // Effect configuration
  final int zSign;
  final double xTarget;
  final double yTarget;

  const KenBurnEffect(
    this.path,
    this.ratio, {
    this.zSign = 0, // Options: {-1, 0, +1}
    this.xTarget = 0, // Options: {0, 0.5, 1}
    this.yTarget = 0, // Options; {0, 0.5, 1}
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Start and end positions
    double xStart = (zSign == 1) ? 0 : (0.5 - xTarget);
    double xEnd = (zSign == 1)
        ? (0.5 - xTarget)
        : ((zSign == -1) ? 0 : (xTarget - 0.5));
    double yStart = (zSign == 1) ? 0 : (0.5 - yTarget);
    double yEnd = (zSign == 1)
        ? (0.5 - yTarget)
        : ((zSign == -1) ? 0 : (yTarget - 0.5));
    double zStart = (zSign == 1) ? 0 : 1;
    double zEnd = (zSign == -1) ? 0 : 1;

    // Interpolation
    double x = xStart * (1 - ratio) + xEnd * ratio;
    double y = yStart * (1 - ratio) + yEnd * ratio;
    double z = zStart * (1 - ratio) + zEnd * ratio;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Transform.translate(
            offset: Offset(
              x * 0.2 * Params.getPlayerWidth(context),
              y * 0.2 * Params.getPlayerHeight(context),
            ),
            child: Transform.scale(
              scale: 1 + z * 0.2,
              child: Stack(
                fit: StackFit.expand,
                children: [Image.file(File(path))],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LayerHeader extends StatelessWidget {
  final String type;
  const _LayerHeader(this.type, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Params.getLayerHeight(context, type),
      width: 28.0,
      margin: const EdgeInsets.fromLTRB(0, 1, 1, 1),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(color: Colors.grey.shade800),
      child: Icon(
        type == "raster"
            ? Icons.photo
            : type == "vector"
            ? Icons.text_fields
            : Icons.music_note,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

class _LayerAssets extends StatelessWidget {
  final int layerIndex;
  const _LayerAssets(this.layerIndex, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded || layerIndex >= state.layers.length) {
          return Container();
        }

        return Stack(
          alignment: const Alignment(0, 0),
          children: [
            Container(
              height: Params.getLayerHeight(
                context,
                state.layers[layerIndex].type,
              ),
              margin: const EdgeInsets.all(1),
              child: Row(
                children: [
                  // Half left screen in blank
                  Container(width: MediaQuery.of(context).size.width / 2),

                  Row(
                    children: state.layers[layerIndex].assets
                        .asMap()
                        .map(
                          (assetIndex, asset) => MapEntry(
                            assetIndex,
                            _Asset(layerIndex, assetIndex),
                          ),
                        )
                        .values
                        .toList(),
                  ),
                  Container(width: MediaQuery.of(context).size.width / 2 - 2),
                ],
              ),
            ),
            AssetSelection(layerIndex),
            // AssetSizer(layerIndex, false),
            // AssetSizer(layerIndex, true),
            (layerIndex != 1) ? DragClosest(layerIndex) : Container(),
          ],
        );
      },
    );
  }
}

class _Asset extends StatelessWidget {
  final int layerIndex;
  final int assetIndex;
  const _Asset(this.layerIndex, this.assetIndex, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded ||
            layerIndex >= state.layers.length ||
            assetIndex >= state.layers[layerIndex].assets.length) {
          return Container();
        }

        Asset asset = state.layers[layerIndex].assets[assetIndex];
        Color backgroundColor = Colors.transparent;
        Color borderColor = Colors.transparent;
        Color textColor = Colors.transparent;
        Color backgroundTextColor = Colors.transparent;

        if (asset.deleted) {
          backgroundColor = Colors.red.shade200;
          borderColor = Colors.red;
          textColor = Colors.red.shade900;
        } else if (layerIndex == 0) {
          backgroundColor = Colors.blue.shade200;
          borderColor = Colors.blue;
          textColor = Colors.white;
          backgroundTextColor = Colors.black.withOpacity(0.5);
        } else if (layerIndex == 1 && asset.title != '') {
          backgroundColor = Colors.blue.shade200;
          borderColor = Colors.blue;
          textColor = Colors.blue.shade900;
        } else if (layerIndex == 2) {
          backgroundColor = Colors.orange.shade200;
          borderColor = Colors.orange;
          textColor = Colors.orange.shade900;
        }

        return GestureDetector(
          child: Container(
            height: Params.getLayerHeight(
              context,
              state.layers[layerIndex].type,
            ),
            width: asset.duration * state.pixelsPerSecond / 1000.0,
            padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                top: BorderSide(width: 2, color: borderColor),
                bottom: BorderSide(width: 2, color: borderColor),
                left: BorderSide(
                  width: (assetIndex == 0) ? 1 : 0,
                  color: borderColor,
                ),
                right: BorderSide(width: 1, color: borderColor),
              ),
              image: (!asset.deleted && asset.thumbnailPath != null)
                  ? DecorationImage(
                      image: FileImage(File(asset.thumbnailPath!)),
                      fit: BoxFit.cover,
                      alignment: Alignment.topLeft,
                    )
                  : null,
            ),
            child: Text(
              asset.title,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                backgroundColor: backgroundTextColor,
                shadows: <Shadow>[
                  Shadow(
                    color: Colors.black,
                    offset: (layerIndex == 0)
                        ? const Offset(1, 1)
                        : const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
          onTap: () => context.read<DirectorBloc>().add(
            SelectAsset(layerIndex, assetIndex),
          ),
          onLongPressStart: (LongPressStartDetails details) {
            // TODO: Implement drag start with BLoC
          },
          onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
            // TODO: Implement drag move with BLoC
            context.read<DirectorBloc>().add(
              DragAsset(layerIndex, assetIndex, details.offsetFromOrigin.dx),
            );
          },
          onLongPressEnd: (LongPressEndDetails details) {
            // TODO: Implement drag end with BLoC
          },
        );
      },
    );
  }
}

// Temporary placeholder widgets until app_bar.dart is fixed
class AppBar1 extends StatelessWidget {
  const AppBar1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      height: isLandscape ? double.infinity : 60,
      width: isLandscape ? 100 : double.infinity,
      color: Colors.grey[300],
      child: const Center(
        child: Text('AppBar1', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}

class AppBar2 extends StatelessWidget {
  const AppBar2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Container(
      height: isLandscape ? double.infinity : 60,
      width: isLandscape ? 100 : double.infinity,
      color: Colors.grey[400],
      child: const Center(
        child: Text('AppBar2', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}
