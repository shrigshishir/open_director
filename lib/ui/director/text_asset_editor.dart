import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/service/director_service.dart';
import 'package:flutter_video_editor_app/service_locator.dart';
import 'package:flutter_video_editor_app/ui/director/params.dart';
import 'package:flutter_video_editor_app/ui/director/text_form.dart';

class TextAssetEditor extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: directorService.editingTextAsset$,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot<Asset?> editingTextAsset) {
        if (editingTextAsset.data == null) return Container();
        return Container(
          height: Params.getTimelineHeight(context),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            border: Border(top: BorderSide(width: 2, color: Colors.blue)),
          ),
          child: TextForm(editingTextAsset.data!),
        );
      },
    );
  }
}
