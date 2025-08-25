class Project {
  int? id;
  String title;
  String? description;
  final DateTime date;
  final int duration;
  String? layersJson;
  String? imagePath;

  Project({
    this.id,
    required this.title,
    this.description,
    required this.date,
    required this.duration,
    this.layersJson,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'duration': duration,
      'layersJson': layersJson,
      'imagePath': imagePath,
    };
    if (id != null) {
      map['_id'] = id;
    }
    return map;
  }

  factory Project.fromMap(Map<String, dynamic> map) => Project(
    id: map['_id'] as int?,
    title: map['title'] as String,
    description: map['description'] as String?,
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    duration: map['duration'] as int,
    layersJson: map['layersJson'] as String?,
    imagePath: map['imagePath'] as String?,
  );

  @override
  String toString() {
    return 'Project {'
        'id: $id, '
        'title: $title, '
        'description: $description, '
        'date: $date, '
        'duration: $duration, '
        'imagePath: $imagePath}';
  }

  // Copy With
  Project copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    int? duration,
    String? layersJson,
    String? imagePath,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      layersJson: layersJson ?? this.layersJson,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
