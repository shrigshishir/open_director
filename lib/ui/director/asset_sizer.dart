import 'dart:ui';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_state.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/ui/director/params.dart';

class AssetSizer extends StatelessWidget {
  final int layerIndex;
  final bool sizerEnd;

  const AssetSizer(this.layerIndex, this.sizerEnd, {Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded) {
          return Container();
        }

        Color color = Colors.transparent;
        double left = -50;
        IconData? iconData;

        if (state.selectedLayerIndex == layerIndex &&
            state.selectedAssetIndex != -1 &&
            layerIndex < state.layers.length &&
            state.selectedAssetIndex < state.layers[layerIndex].assets.length) {
          Asset asset =
              state.layers[layerIndex].assets[state.selectedAssetIndex];

          if (asset.type == AssetType.text || asset.type == AssetType.image) {
            left = asset.begin * state.pixelsPerSecond / 1000.0;

            if (sizerEnd) {
              left += asset.duration * state.pixelsPerSecond / 1000.0;
              // TODO: Add sizer drag logic when implemented in state
              // if (state.isSizerDraggingEnd) {
              //   left += state.dxSizerDrag;
              // }
              if (left <
                  (asset.begin + 1000) * state.pixelsPerSecond / 1000.0) {
                left = (asset.begin + 1000) * state.pixelsPerSecond / 1000.0;
              }
              iconData = Icons.arrow_right;
            } else {
              // TODO: Add sizer drag logic when implemented in state
              // if (!state.isSizerDraggingEnd) {
              //   left += state.dxSizerDrag;
              // }
              if (left >
                  (asset.begin + asset.duration - 1000) *
                      state.pixelsPerSecond /
                      1000.0) {
                left =
                    (asset.begin + asset.duration - 1000) *
                    state.pixelsPerSecond /
                    1000.0;
              }
              if (left < 0) {
                left = 0;
              }
              left -= 28;
              iconData = Icons.arrow_left;
            }

            // TODO: Implement drag state detection
            // if (state.dxSizerDrag == 0) {
            color = Colors.pinkAccent;
            // } else {
            //   color = Colors.greenAccent;
            // }
          }
        }

        return Positioned(
          left: MediaQuery.of(context).size.width / 2 + left,
          child: GestureDetector(
            child: Container(
              height: layerIndex < state.layers.length
                  ? Params.getLayerHeight(
                      context,
                      state.layers[layerIndex].type,
                    )
                  : 50,
              width: 30,
              color: color,
              child: iconData != null
                  ? Icon(iconData, size: 30, color: Colors.white)
                  : null,
            ),
            onHorizontalDragStart: (detail) {
              // TODO: Implement sizer drag start event when available
            },
            onHorizontalDragUpdate: (detail) {
              // TODO: Implement sizer drag update event when available
            },
            onHorizontalDragEnd: (detail) {
              // TODO: Implement sizer drag end event when available
            },
          ),
        );
      },
    );
  }
}
