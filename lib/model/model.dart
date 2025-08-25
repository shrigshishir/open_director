// import removed: 'package:flutter/foundation.dart';

class Layer {
  final String type; // TODO: enums
  final List<Asset> assets;
  final double volume;

  Layer({required this.type, List<Asset>? assets, required this.volume})
    : assets = assets ?? <Asset>[];

  Layer.clone(Layer layer)
    : type = layer.type,
      assets = layer.assets.map((asset) => Asset.clone(asset)).toList(),
      volume = layer.volume;

  factory Layer.fromJson(Map<String, dynamic> map) => Layer(
    type: map['type'] as String,
    assets:
        (map['assets'] as List<dynamic>?)
            ?.map((json) => Asset.fromJson(json))
            .toList() ??
        [],
    volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'assets': assets.map((asset) => asset.toJson()).toList(),
    'volume': volume,
  };
}

enum AssetType { video, image, text, audio }

class Asset {
  final AssetType type;
  final String srcPath;
  String? thumbnailPath;
  String? thumbnailMedPath;
  String? title;
  int? duration;
  int? begin;
  int? cutFrom;
  int? kenBurnZSign;
  double? kenBurnXTarget;
  double? kenBurnYTarget;
  double? x;
  double? y;
  String? font;
  double? fontSize;
  int? fontColor;
  final double? alpha;
  final double? borderw;
  final int? bordercolor;
  final int? shadowcolor;
  final double? shadowx;
  final double? shadowy;
  final bool? box;
  final double? boxborderw;
  int? boxcolor;
  bool? deleted;

  Asset({
    required this.type,
    required this.srcPath,
    this.thumbnailPath,
    this.thumbnailMedPath,
    this.title,
    this.duration,
    this.begin,
    this.cutFrom,
    this.kenBurnZSign,
    this.kenBurnXTarget,
    this.kenBurnYTarget,
    this.x,
    this.y,
    this.font,
    this.fontSize,
    this.fontColor,
    this.alpha,
    this.borderw,
    this.bordercolor,
    this.shadowcolor,
    this.shadowx,
    this.shadowy,
    this.box,
    this.boxborderw,
    this.boxcolor,
    this.deleted,
  });

  Asset.clone(Asset asset)
    : type = asset.type,
      srcPath = asset.srcPath,
      thumbnailPath = asset.thumbnailPath,
      thumbnailMedPath = asset.thumbnailMedPath,
      title = asset.title,
      duration = asset.duration,
      begin = asset.begin,
      cutFrom = asset.cutFrom,
      kenBurnZSign = asset.kenBurnZSign,
      kenBurnXTarget = asset.kenBurnXTarget,
      kenBurnYTarget = asset.kenBurnYTarget,
      x = asset.x,
      y = asset.y,
      font = asset.font,
      fontSize = asset.fontSize,
      fontColor = asset.fontColor,
      alpha = asset.alpha,
      borderw = asset.borderw,
      bordercolor = asset.bordercolor,
      shadowcolor = asset.shadowcolor,
      shadowx = asset.shadowx,
      shadowy = asset.shadowy,
      box = asset.box,
      boxborderw = asset.boxborderw,
      boxcolor = asset.boxcolor,
      deleted = asset.deleted;

  factory Asset.fromJson(Map<String, dynamic> map) => Asset(
    type: Asset.getAssetTypeFromString(map['type'] as String),
    srcPath: map['srcPath'] as String,
    thumbnailPath: map['thumbnailPath'] as String?,
    thumbnailMedPath: map['thumbnailMedPath'] as String?,
    title: map['title'] as String?,
    duration: map['duration'] as int?,
    begin: map['begin'] as int?,
    cutFrom: map['cutFrom'] as int?,
    kenBurnZSign: map['kenBurnZSign'] as int?,
    kenBurnXTarget: (map['kenBurnXTarget'] as num?)?.toDouble(),
    kenBurnYTarget: (map['kenBurnYTarget'] as num?)?.toDouble(),
    x: (map['x'] as num?)?.toDouble(),
    y: (map['y'] as num?)?.toDouble(),
    font: map['font'] as String?,
    fontSize: (map['fontSize'] as num?)?.toDouble(),
    fontColor: map['fontColor'] as int?,
    alpha: (map['alpha'] as num?)?.toDouble(),
    borderw: (map['borderw'] as num?)?.toDouble(),
    bordercolor: map['bordercolor'] as int?,
    shadowcolor: map['shadowcolor'] as int?,
    shadowx: (map['shadowx'] as num?)?.toDouble(),
    shadowy: (map['shadowy'] as num?)?.toDouble(),
    box: map['box'] as bool?,
    boxborderw: (map['boxborderw'] as num?)?.toDouble(),
    boxcolor: map['boxcolor'] as int?,
    deleted: map['deleted'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'srcPath': srcPath,
    'thumbnailPath': thumbnailPath,
    'thumbnailMedPath': thumbnailMedPath,
    'title': title,
    'duration': duration,
    'begin': begin,
    'cutFrom': cutFrom,
    'kenBurnZSign': kenBurnZSign,
    'kenBurnXTarget': kenBurnXTarget,
    'kenBurnYTarget': kenBurnYTarget,
    'x': x,
    'y': y,
    'font': font,
    'fontSize': fontSize,
    'fontColor': fontColor,
    'alpha': alpha,
    'borderw': borderw,
    'bordercolor': bordercolor,
    'shadowcolor': shadowcolor,
    'shadowx': shadowx,
    'shadowy': shadowy,
    'box': box,
    'boxborderw': boxborderw,
    'boxcolor': boxcolor,
    'deleted': deleted,
  };

  static AssetType getAssetTypeFromString(String assetTypeAsString) {
    for (AssetType element in AssetType.values) {
      if (element.toString() == assetTypeAsString ||
          element.name == assetTypeAsString) {
        return element;
      }
    }
    // Default fallback
    return AssetType.video;
  }
}
// ...existing code...
// (All legacy Asset code removed; only the new null-safe Asset class and its methods remain above)

class Selected {
  int layerIndex;
  int assetIndex;
  double initScrollOffset;
  double incrScrollOffset;
  double dragX;
  int closestAsset;
  Selected(
    this.layerIndex,
    this.assetIndex, {
    this.dragX = 0,
    this.closestAsset = -1,
    this.initScrollOffset = 0,
    this.incrScrollOffset = 0,
  });

  bool isSelected(int layerIndex, int assetIndex) {
    return (layerIndex == this.layerIndex && assetIndex == this.assetIndex);
  }
}
