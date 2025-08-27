import 'dart:ui';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_event.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/ui/director/params.dart';
import 'package:flutter_video_editor_app/ui/director/text_form.dart';

class TextPlayerEditor extends StatelessWidget {
  final Asset _asset;

  const TextPlayerEditor(this._asset, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var txtController = TextEditingController();
    txtController.text = _asset.title;
    Font font = Font.getByPath(_asset.font);

    return GestureDetector(
      onPanUpdate: (details) {
        // Create a new asset with updated position
        Asset newAsset = Asset.clone(_asset);
        newAsset.x += details.delta.dx / Params.getPlayerWidth(context);
        newAsset.y += details.delta.dy / Params.getPlayerHeight(context);

        // Clamp values to bounds
        if (newAsset.x < 0) {
          newAsset.x = 0;
        }
        if (newAsset.x > 0.85) {
          newAsset.x = 0.85;
        }
        if (newAsset.y < 0) {
          newAsset.y = 0;
        }
        if (newAsset.y > 0.85) {
          newAsset.y = 0.85;
        }

        context.read<DirectorBloc>().add(UpdateTextAsset(newAsset));
      },
      child: Container(
        width: Params.getPlayerWidth(context),
        child: TextField(
          controller: txtController,
          minLines: 1,
          maxLines: 1,
          autocorrect:
              false, //Doesn´t work: https://github.com/flutter/flutter/issues/22828
          decoration: InputDecoration(
            fillColor: Colors.red,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.pinkAccent, width: 2.0),
            ),
            contentPadding: const EdgeInsets.fromLTRB(0, 1, 0, 1),
            hintStyle: TextStyle(color: Colors.grey.shade200),
            hintText: 'Click to edit text',
          ),
          /*strutStyle: StrutStyle(
              height: 1.0,
            ),*/
          style: TextStyle(
            height: 1.0,
            fontSize:
                _asset.fontSize *
                Params.getPlayerWidth(context) /
                MediaQuery.of(context).textScaleFactor,
            fontStyle: font.style,
            fontFamily: font.family,
            fontWeight: font.weight,
            color: Color(_asset.fontColor),
            backgroundColor: Color(_asset.boxcolor),
          ),
          onChanged: (newVal) {
            Asset newAsset = Asset.clone(_asset);
            newAsset.title = newVal;
            context.read<DirectorBloc>().add(UpdateTextAsset(newAsset));
          },
        ),
      ),
    );
  }
}
