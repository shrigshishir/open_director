import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_video_editor_app/bloc/director/director_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_state.dart';
import 'package:flutter_video_editor_app/bloc/director/director_event.dart';
import 'package:flutter_video_editor_app/ui/director/params.dart';
import 'package:flutter_video_editor_app/model/model.dart';

class ColorEditor extends StatelessWidget {
  const ColorEditor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded || !state.editingColor) {
          return Container();
        }

        return Container(
          height: Params.getTimelineHeight(context),
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            border: Border(top: BorderSide(width: 2, color: Colors.blue)),
          ),
          child: ColorForm(),
        );
      },
    );
  }
}

class ColorForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded) return Container();

        int fontColor = 0;
        if (state.editingColorType == 'fontColor') {
          fontColor = state.editingTextAsset?.fontColor ?? 0;
        } else if (state.editingColorType == 'boxcolor') {
          fontColor = state.editingTextAsset?.boxcolor ?? 0;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width - 130,
              child: Wrap(
                children: [
                  Container(
                    height:
                        (MediaQuery.of(context).orientation ==
                            Orientation.landscape)
                        ? 116
                        : 320,
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: ColorPicker(
                      pickerColor: Color(fontColor),
                      paletteType: PaletteType.hsv,
                      enableAlpha: true,
                      colorPickerWidth: 240,
                      pickerAreaHeightPercent: 0.8,
                      onColorChanged: (color) {
                        final editingTextAsset = state.editingTextAsset;
                        if (editingTextAsset == null) return;
                        Asset newAsset = Asset.clone(editingTextAsset);
                        if (state.editingColorType == 'fontColor') {
                          newAsset.fontColor = color.value;
                        } else if (state.editingColorType == 'boxcolor') {
                          newAsset.boxcolor = color.value;
                        }
                        context.read<DirectorBloc>().add(
                          UpdateTextAsset(newAsset),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Column(
                children: <Widget>[
                  ElevatedButton(
                    child: Text('SELECT'),
                    onPressed: () {
                      context.read<DirectorBloc>().add(StopEditingColor());
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
