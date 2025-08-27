import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_state.dart';
import 'package:flutter_video_editor_app/bloc/director/director_event.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/ui/director/params.dart';

class AssetSelection extends StatelessWidget {
  final int layerIndex;

  const AssetSelection(this.layerIndex, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded) {
          return Container();
        }

        Color borderColor = Colors.pinkAccent;
        double left, width;

        if (state.selectedLayerIndex == layerIndex &&
            state.selectedAssetIndex != -1) {
          // TODO: Add proper drag state detection when implemented in DirectorState
          // if (state.isDragging || state.isSizerDragging) {
          //   borderColor = Colors.greenAccent;
          // }

          if (layerIndex < state.layers.length &&
              state.selectedAssetIndex <
                  state.layers[layerIndex].assets.length) {
            Asset asset =
                state.layers[layerIndex].assets[state.selectedAssetIndex];
            left = asset.begin * state.pixelsPerSecond / 1000.0;
            width = asset.duration * state.pixelsPerSecond / 1000.0;

            // TODO: Handle drag and sizer logic when implemented in state
            // left += state.dragX + state.incrScrollOffset;

            if (left < 0) {
              left = 0;
            }
          } else {
            borderColor = Colors.transparent;
            left = -1;
            width = 0;
          }
        } else {
          borderColor = Colors.transparent;
          left = -1;
          width = 0;
        }

        return Positioned(
          left: MediaQuery.of(context).size.width / 2 + left + 1,
          child: GestureDetector(
            child: Container(
              height: layerIndex < state.layers.length
                  ? Params.getLayerHeight(
                      context,
                      state.layers[layerIndex].type,
                    )
                  : 50,
              width: width,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.25),
                border: Border.all(width: 3, color: borderColor),
              ),
            ),
            onLongPressStart: (LongPressStartDetails details) {
              // TODO: Implement drag start event
              if (state.selectedAssetIndex != -1) {
                context.read<DirectorBloc>().add(
                  SelectAsset(layerIndex, state.selectedAssetIndex),
                );
              }
            },
            onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
              // TODO: Implement drag move event when available
              if (state.selectedAssetIndex != -1) {
                context.read<DirectorBloc>().add(
                  DragAsset(
                    layerIndex,
                    state.selectedAssetIndex,
                    details.offsetFromOrigin.dx,
                  ),
                );
              }
            },
            onLongPressEnd: (LongPressEndDetails details) {
              // TODO: Implement drag end event when available
            },
          ),
        );
      },
    );
  }
}
