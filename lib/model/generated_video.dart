class GeneratedVideo {
  int? id;
  final int projectId;
  final String path;
  final DateTime date;
  final String? resolution;
  final String? thumbnail;

  GeneratedVideo({
    this.id,
    required this.projectId,
    required this.path,
    required this.date,
    this.resolution,
    this.thumbnail,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'projectId': projectId,
      'path': path,
      'date': date.millisecondsSinceEpoch,
      'resolution': resolution,
      'thumbnail': thumbnail,
    };
    if (id != null) {
      map['_id'] = id;
    }
    return map;
  }

  factory GeneratedVideo.fromMap(Map<String, dynamic> map) => GeneratedVideo(
    id: map['_id'] as int?,
    projectId: map['projectId'] as int,
    path: map['path'] as String,
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    resolution: map['resolution'] as String?,
    thumbnail: map['thumbnail'] as String?,
  );

  @override
  String toString() {
    return 'GeneratedVideo {'
        'id: $id, '
        'projectId: $projectId, '
        'path: $path, '
        'date: $date, '
        'resolution: $resolution, '
        'thumbnail: $thumbnail}';
  }

  // Copy With
  GeneratedVideo copyWith({
    int? id,
    int? projectId,
    String? path,
    DateTime? date,
    String? resolution,
    String? thumbnail,
  }) {
    return GeneratedVideo(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      path: path ?? this.path,
      date: date ?? this.date,
      resolution: resolution ?? this.resolution,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }
}
