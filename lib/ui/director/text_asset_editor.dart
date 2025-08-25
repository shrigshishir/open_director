import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/service/director_service.dart';
import 'package:flutter_video_editor_app/service_locator.dart';

class TextAssetEditor extends StatelessWidget {
  final directorService = locator.get<DirectorService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Asset?>(
      stream: directorService.editingTextAsset$,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot<Asset?> editingTextAsset) {
        if (editingTextAsset.data == null) return Container();
        return Container(
          height: 100.0, // Replace with a valid height or your desired value
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            border: Border(top: BorderSide(width: 2, color: Colors.blue)),
          ),
          child: Text(editingTextAsset.data?.toString() ?? ''),
        );
      },
    );
  }
}
