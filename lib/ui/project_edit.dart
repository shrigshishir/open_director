import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_video_editor_app/bloc/project/project_bloc.dart';
import 'package:flutter_video_editor_app/bloc/project/project_event.dart';
import 'package:flutter_video_editor_app/model/project.dart';
import 'package:flutter_video_editor_app/ui/director.dart';

class ProjectEdit extends StatefulWidget {
  final Project? project;

  const ProjectEdit(this.project, {Key? key}) : super(key: key);

  @override
  _ProjectEditState createState() => _ProjectEditState();
}

class _ProjectEditState extends State<ProjectEdit> {
  late Project _editingProject;

  @override
  void initState() {
    super.initState();
    if (widget.project == null) {
      // Create a new project
      _editingProject = Project(
        title: '',
        description: '',
        date: DateTime.now(),
        duration: 0,
      );
    } else {
      // Edit existing project - create a copy to avoid modifying the original
      _editingProject = Project(
        title: widget.project!.title,
        description: widget.project!.description,
        date: widget.project!.date,
        duration: widget.project!.duration,
        layersJson: widget.project!.layersJson,
      );
      _editingProject.id = widget.project!.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((_editingProject.id == null) ? 'New video' : 'Edit title'),
      ),
      body: _ProjectEditForm(_editingProject),
      resizeToAvoidBottomInset: true,
    );
  }
}

class _ProjectEditForm extends StatefulWidget {
  final Project project;

  const _ProjectEditForm(this.project, {Key? key}) : super(key: key);

  @override
  _ProjectEditFormState createState() => _ProjectEditFormState();
}

class _ProjectEditFormState extends State<_ProjectEditForm> {
  // Necessary static
  // https://github.com/flutter/flutter/issues/20042
  static final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;

  @override
  void initState() {
    super.initState();
    _title = widget.project.title;
    _description = widget.project.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.08,
            MediaQuery.of(context).size.height * 0.05,
            MediaQuery.of(context).size.width * 0.08,
            MediaQuery.of(context).size.height * 0.5,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  initialValue: widget.project.title,
                  maxLength: 75,
                  onSaved: (value) {
                    _title = value ?? "New project title";
                  },
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter a title for your video project',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                Padding(padding: EdgeInsets.only(top: 10)),
                TextFormField(
                  initialValue: widget.project.description,
                  maxLines: 3,
                  maxLength: 1000,
                  onSaved: (value) {
                    _description = value ?? "This is a new project description";
                  },
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: 10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    ElevatedButton(
                      child: Text('OK'),
                      onPressed: () async {
                        // If the form is valid
                        if (_formKey.currentState?.validate() ?? false) {
                          // To call onSave in TextFields
                          _formKey.currentState?.save();

                          // To hide soft keyboard
                          FocusScope.of(context).requestFocus(FocusNode());

                          // Create updated project
                          final updatedProject = Project(
                            title: _title,
                            description: _description,
                            date: widget.project.date,
                            duration: widget.project.duration,
                            layersJson: widget.project.layersJson,
                          );
                          updatedProject.id = widget.project.id;

                          if (widget.project.id == null) {
                            // Create new project
                            context.read<ProjectBloc>().add(
                              CreateProject(updatedProject),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DirectorScreen(updatedProject),
                              ),
                            );
                          } else {
                            // Update existing project
                            context.read<ProjectBloc>().add(
                              UpdateProject(updatedProject),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      onTap: () {
        // To hide soft keyboard
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }
}
