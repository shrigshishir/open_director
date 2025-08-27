import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_bloc.dart';
import 'package:flutter_video_editor_app/bloc/director/director_state.dart';
import 'package:flutter_video_editor_app/ui/director/params.dart';
import 'package:flutter_video_editor_app/ui/director/text_form.dart';

class TextAssetEditor extends StatelessWidget {
  const TextAssetEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectorBloc, DirectorState>(
      builder: (context, state) {
        if (state is! DirectorLoaded) {
          return Container();
        }
        if (state.editingTextAsset == null) return Container();
        return Container(
          height: Params.getTimelineHeight(context),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            border: Border(top: BorderSide(width: 2, color: Colors.blue)),
          ),
          child: TextForm(state.editingTextAsset!),
        );
      },
    );
  }
}
