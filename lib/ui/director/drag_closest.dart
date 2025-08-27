import 'dart:ui';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_state.dart';
import 'package:flutter_video_editor_app/ui/director/params.dart';

class DragClosest extends StatelessWidget {
  final int layerIndex;

  const DragClosest(this.layerIndex, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded) return Container();

        Color color;
        double left;

        // TODO: Implement drag closest logic with BLoC
        // This requires implementing isDragging state and closest asset tracking
        // For now, return transparent container as placeholder

        color = Colors.transparent;
        left = -1;

        return Positioned(
          left: MediaQuery.of(context).size.width / 2 + left - 2,
          child: Container(
            height: Params.getLayerHeight(
              context,
              state.layers[layerIndex].type,
            ),
            width: 3,
            color: color,
          ),
        );
      },
    );
  }
}
