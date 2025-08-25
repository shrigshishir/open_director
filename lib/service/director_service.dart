import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_video_editor_app/dao/project_dao.dart';
// import 'package:flutter_video_editor_app/model/generated_video.dart';
import 'package:flutter_video_editor_app/model/model.dart';
import 'package:flutter_video_editor_app/model/project.dart';
// import 'package:flutter_video_editor_app/service/director/generator.dart';
import 'package:flutter_video_editor_app/service/director/layer_player.dart';
import 'package:flutter_video_editor_app/service/project_service.dart';
import 'package:flutter_video_editor_app/service_locator.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DirectorService {
  Project? project;
  final logger = locator.get<Logger>();
  final projectService = locator.get<ProjectService>();
  // final generator = locator.get<Generator>();
  final projectDao = locator.get<ProjectDao>();

  List<Layer> layers = [];

  // Ensure default layers exist
  void _ensureDefaultLayers() {
    if (layers.isEmpty) {
      layers = [
        Layer(type: "raster", volume: 0.1),
        Layer(type: "vector", volume: 0.0),
        Layer(type: "audio", volume: 1.0),
      ];
    }
  }

  // Flags for concurrency
  bool isEntering = false;
  bool isExiting = false;
  bool isPlaying = false;
  bool isPreviewing = false;
  int mainLayerIndexForConcurrency = -1;
  bool isDragging = false;
  bool isSizerDragging = false;
  bool isCutting = false;
  bool isScaling = false;
  bool isAdding = false;
  bool isDeleting = false;
  bool isGenerating = false;
  bool get isOperating =>
      (isEntering ||
      isExiting ||
      isPlaying ||
      isPreviewing ||
      isDragging ||
      isSizerDragging ||
      isCutting ||
      isScaling ||
      isAdding ||
      isDeleting ||
      isGenerating);
  double? _pixelsPerSecondOnInitScale;
  double? _scrollOffsetOnInitScale;
  double dxSizerDrag = 0;
  bool isSizerDraggingEnd = false;

  BehaviorSubject<bool> _filesNotExist = BehaviorSubject.seeded(false);
  Stream<bool> get filesNotExist$ => _filesNotExist.stream;
  bool get filesNotExist => _filesNotExist.value;

  List<LayerPlayer?> layerPlayers = [];

  ScrollController scrollController = ScrollController();

  final BehaviorSubject<bool> _layersChanged = BehaviorSubject.seeded(false);
  Stream<bool> get layersChanged$ => _layersChanged.stream;
  bool get layersChanged => _layersChanged.value;

  final BehaviorSubject<Selected> _selected = BehaviorSubject.seeded(
    Selected(-1, -1),
  );
  Stream<Selected> get selected$ => _selected.stream;
  Selected get selected => _selected.value;
  Asset? get assetSelected {
    if (selected.layerIndex == -1 || selected.assetIndex == -1) return null;
    return layers[selected.layerIndex].assets[selected.assetIndex];
  }

  // ignore: constant_identifier_names
  static const double DEFAULT_PIXELS_PER_SECONDS = 100.0 / 5.0;
  final BehaviorSubject<double> _pixelsPerSecond = BehaviorSubject.seeded(
    DEFAULT_PIXELS_PER_SECONDS,
  );
  Stream<double> get pixelsPerSecond$ => _pixelsPerSecond.stream;
  double get pixelsPerSecond => _pixelsPerSecond.value;

  final BehaviorSubject<bool> _appBar = BehaviorSubject.seeded(false);
  Stream<bool> get appBar$ => _appBar.stream;

  final BehaviorSubject<int> _position = BehaviorSubject.seeded(0);
  Stream<int> get position$ => _position.stream;
  int get position => _position.value;

  final BehaviorSubject<Asset?> _editingTextAsset = BehaviorSubject.seeded(
    null,
  );
  Stream<Asset?> get editingTextAsset$ => _editingTextAsset.stream;
  Asset? get editingTextAsset => _editingTextAsset.value;
  set editingTextAsset(Asset? value) {
    _editingTextAsset.add(value);
    _appBar.add(true);
  }

  final BehaviorSubject<String?> _editingColor = BehaviorSubject.seeded(null);
  Stream<String?> get editingColor$ => _editingColor.stream;
  String? get editingColor => _editingColor.value;
  set editingColor(String? value) {
    _editingColor.add(value);
    _appBar.add(true);
  }

  String get positionMinutes {
    int minutes = (position / 1000 / 60).floor();
    return (minutes < 10) ? '0$minutes' : minutes.toString();
  }

  String get positionSeconds {
    int minutes = (position / 1000 / 60).floor();
    double seconds = (((position / 1000 - minutes * 60) * 10).floor() / 10);
    return (seconds < 10) ? '0$seconds' : seconds.toString();
  }

  int get duration {
    int maxDuration = 0;
    for (int i = 0; i < layers.length; i++) {
      for (int j = layers[i].assets.length - 1; j >= 0; j--) {
        if (!(i == 1 && layers[i].assets[j].title == '')) {
          int dur =
              (layers[i].assets[j].begin ?? 0) +
              (layers[i].assets[j].duration ?? 0);
          maxDuration = math.max(maxDuration, dur);
          break;
        }
      }
    }
    return maxDuration;
  }

  DirectorService() {
    scrollController.addListener(_listenerScrollController);
    _layersChanged.listen((bool onData) => _saveProject());
  }

  get generator => null;

  dispose() {
    _layersChanged.close();
    _selected.close();
    _pixelsPerSecond.close();
    _position.close();
    _appBar.close();
    _editingTextAsset.close();
    _editingColor.close();
    _filesNotExist.close();
  }

  setProject(Project project) async {
    isEntering = true;

    _position.add(0);
    _selected.add(Selected(-1, -1));
    _editingTextAsset.add(null);
    _editingColor.add(null);
    _pixelsPerSecond.add(DEFAULT_PIXELS_PER_SECONDS);
    _appBar.add(true);

    if (project != project) {
      project = project;
      if (project.layersJson == null) {
        layers = [
          // TODO: audio mixing between layers
          Layer(type: "raster", volume: 0.1),
          Layer(type: "vector", volume: 0.0),
          Layer(type: "audio", volume: 1.0),
        ];
      } else {
        layers = List<Layer>.from(
          json
              .decode(project.layersJson!)
              .map((layerMap) => Layer.fromJson(layerMap)),
        ).toList();
        _filesNotExist.add(checkSomeFileNotExists());
      }
      _layersChanged.add(true);

      layerPlayers = [];
      for (int i = 0; i < layers.length; i++) {
        LayerPlayer? layerPlayer;
        if (i != 1) {
          layerPlayer = LayerPlayer(layers[i]);
          await layerPlayer.initialize();
        } else {
          layerPlayer = null;
        }
        layerPlayers.add(layerPlayer);
      }
    }
    isEntering = false;
    await _previewOnPosition();
  }

  checkSomeFileNotExists() {
    bool _someFileNotExists = false;
    for (int i = 0; i < layers.length; i++) {
      for (int j = 0; j < layers[i].assets.length; j++) {
        Asset asset = layers[i].assets[j];
        if (asset.srcPath != '' && !File(asset.srcPath).existsSync()) {
          asset.deleted = true;
          _someFileNotExists = true;
          print(asset.srcPath + ' does not exists');
        }
      }
    }
    return _someFileNotExists;
  }

  exitAndSaveProject() async {
    if (isPlaying) await stop();
    if (isOperating) return false;
    isExiting = true;
    _saveProject();

    Future.delayed(Duration(milliseconds: 500), () {
      project = null;
      for (var layerPlayer in layerPlayers) {
        layerPlayer?.dispose();
        layerPlayer = null;
      }
      isExiting = false;
    });

    _deleteThumbnailsNotUsed();
    return true;
  }

  _saveProject() {
    if (project != null) {
      project!.layersJson = json.encode(layers);
      project!.imagePath = layers[0].assets.isNotEmpty
          ? getFirstThumbnailMedPath()
          : null;
      projectService.update(project!);
    }
  }

  String? getFirstThumbnailMedPath() {
    for (int i = 0; i < layers[0].assets.length; i++) {
      Asset asset = layers[0].assets[i];
      if (asset.thumbnailMedPath != null &&
          File(asset.thumbnailMedPath!).existsSync()) {
        return asset.thumbnailMedPath;
      }
    }
    return null;
  }

  _listenerScrollController() async {
    // When playing position is defined by the video player
    if (isPlaying) return;
    // In other case by the scroll manually
    _position.sink.add(
      ((scrollController.offset / pixelsPerSecond) * 1000).floor(),
    );
    // Delayed 10 to get more fuidity in scroll and preview
    Future.delayed(Duration(milliseconds: 10), () {
      _previewOnPosition();
    });
  }

  endScroll() async {
    _position.sink.add(
      ((scrollController.offset / pixelsPerSecond) * 1000).floor(),
    );
    // Delayed 200 because position may not be updated at this time
    Future.delayed(Duration(milliseconds: 200), () {
      _previewOnPosition();
    });
  }

  _previewOnPosition() async {
    if (filesNotExist) return;
    if (isOperating) return;
    isPreviewing = true;
    scrollController.removeListener(_listenerScrollController);

    if (layers.isEmpty) return;

    await layerPlayers[0]?.preview(position);
    _position.add(position);

    scrollController.addListener(_listenerScrollController);
    isPreviewing = false;
  }

  play() async {
    if (filesNotExist) {
      _filesNotExist.add(true);
      return;
    }
    // if (isOperating) return;
    if (position >= duration) return;
    logger.i('DirectorService.play()');
    isPlaying = true;
    scrollController.removeListener(_listenerScrollController);
    _appBar.add(true);
    _selected.add(Selected(-1, -1));

    int mainLayer = mainLayerForConcurrency();
    print('mainLayer: $mainLayer');

    for (int i = 0; i < layers.length; i++) {
      if (i == 1) continue;
      if (i == mainLayer) {
        await layerPlayers[i]?.play(
          position,
          // onMove: (int newPosition) {
          //   _position.add(newPosition);
          //   scrollController.animateTo(
          //     (300 + newPosition) / 1000 * pixelsPerSecond,
          //     duration: Duration(milliseconds: 300),
          //     curve: Curves.linear,
          //   );
          // },
          // onEnd: () {
          //   isPlaying = false;
          //   _appBar.add(true);
          // },
        );
      } else {
        await layerPlayers[i]?.play(position);
      }
      _position.add(position);
    }
  }

  stop() async {
    if ((isOperating && !isPlaying) || !isPlaying) return;
    print('>> DirectorService.stop()');
    for (int i = 0; i < layers.length; i++) {
      if (i == 1) continue;
      await layerPlayers[i]?.stop();
    }
    isPlaying = false;
    scrollController.addListener(_listenerScrollController);
    _appBar.add(true);
  }

  int mainLayerForConcurrency() {
    int mainLayer = 0, mainLayerDuration = 0;
    for (int i = 0; i < layers.length; i++) {
      if (i != 1 &&
          layers[i].assets.isNotEmpty &&
          (layers[i].assets.last.begin ?? 0) +
                  (layers[i].assets.last.duration ?? 0) >
              mainLayerDuration) {
        mainLayer = i;
        mainLayerDuration =
            (layers[i].assets.last.begin ?? 0) +
            (layers[i].assets.last.duration ?? 0);
      }
    }
    return mainLayer;
  }

  add(AssetType assetType) async {
    _ensureDefaultLayers();
    // if (isOperating) return;
    isAdding = true;
    print('>> DirectorService.add($assetType)');

    if (assetType == AssetType.video ||
        assetType == AssetType.image ||
        assetType == AssetType.audio) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: assetType == AssetType.video
            ? FileType.video
            : assetType == AssetType.image
            ? FileType.image
            : FileType.audio,
      );
      if (result == null || result.files.isEmpty) {
        isAdding = false;
        return;
      }
      final fileList = result.files.map((f) => File(f.path!)).toList();
      if (assetType == AssetType.video) {
        for (final file in fileList) {
          await _addAssetToLayer(0, AssetType.video, file.path);
          // TODO: Generate video thumbnails if needed
        }
      } else if (assetType == AssetType.image) {
        for (final file in fileList) {
          await _addAssetToLayer(0, AssetType.image, file.path);
          _generateKenBurnEffects(layers[0].assets.last);
          // TODO: Generate image thumbnails if needed
        }
      } else if (assetType == AssetType.audio) {
        for (final file in fileList) {
          await _addAssetToLayer(2, AssetType.audio, file.path);
        }
      }
    } else if (assetType == AssetType.text) {
      editingTextAsset = Asset(
        type: AssetType.text,
        begin: 0, // TODO:
        duration: 5000,
        title: '',
        srcPath: '',
      );
    }
    isAdding = false;
  }

  // _sortFilesByDate(Map<String, String> filePaths) {
  //   var fileList = filePaths.entries.map((entry) => File(entry.value)).toList();
  //   fileList.sort((file1, file2) {
  //     return file1.lastModifiedSync().compareTo(file2.lastModifiedSync());
  //   });
  //   return fileList;
  // }

  _generateKenBurnEffects(Asset asset) {
    asset.kenBurnZSign = math.Random().nextInt(2) - 1;
    asset.kenBurnXTarget = (math.Random().nextInt(2) / 2).toDouble();
    asset.kenBurnYTarget = (math.Random().nextInt(2) / 2).toDouble();
    if (asset.kenBurnZSign == 0 &&
        asset.kenBurnXTarget == 0.5 &&
        asset.kenBurnYTarget == 0.5) {
      asset.kenBurnZSign = 1;
    }
  }

  // _generateAllVideoThumbnails(List<Asset> assets) async {}
  // _generateAllImageThumbnails(List<Asset> assets) async {}

  editTextAsset() {
    if (assetSelected == null) return;
    if (assetSelected?.type != AssetType.text) return;
    editingTextAsset = Asset.clone(assetSelected!);
    scrollController.animateTo(
      assetSelected!.begin! / 1000 * pixelsPerSecond,
      duration: Duration(milliseconds: 300),
      curve: Curves.linear,
    );
  }

  saveTextAsset() {
    final asset = editingTextAsset;
    if (asset == null) return;
    if (asset.title == '') {
      asset.title = 'No title';
    }
    if (assetSelected == null) {
      asset.begin = position;
      layers[1].assets.add(asset);
      reorganizeTextAssets(1);
    } else {
      layers[1].assets[selected.assetIndex] = asset;
    }
    _layersChanged.add(true);
    editingTextAsset = null;
  }

  reorganizeTextAssets(int layerIndex) {
    if (layers[layerIndex].assets.isEmpty) return;
    // After adding an asset in a position (begin = position),
    // it´s neccesary to sort
    layers[layerIndex].assets.sort(
      (a, b) => (a.begin ?? 0).compareTo(b.begin ?? 0),
    );

    // Configuring other assets and spaces after that
    for (int i = 1; i < layers[layerIndex].assets.length; i++) {
      Asset asset = layers[layerIndex].assets[i];
      Asset prevAsset = layers[layerIndex].assets[i - 1];

      if (prevAsset.title == '' && asset.title == '') {
        asset.begin = prevAsset.begin ?? 0;
        asset.duration = (asset.duration ?? 0) + (prevAsset.duration ?? 0);
        prevAsset.duration = 0; // To delete at the end
      } else if (prevAsset.title == '' && asset.title != '') {
        prevAsset.duration = (asset.begin ?? 0) - (prevAsset.begin ?? 0);
      } else if (prevAsset.title != '' && asset.title == '') {
        asset.duration =
            (asset.duration ?? 0) -
            ((prevAsset.begin ?? 0) +
                (prevAsset.duration ?? 0) -
                (asset.begin ?? 0));
        asset.duration = math.max(asset.duration ?? 0, 0);
        asset.begin = (prevAsset.begin ?? 0) + (prevAsset.duration ?? 0);
      } else if (prevAsset.title != '' && asset.title != '') {
        // Nothing, only insert space in a second loop if it´s neccesary
      }
    }

    // Remove duplicated spaces
    layers[layerIndex].assets.removeWhere(
      (asset) => (asset.duration ?? 0) <= 0,
    );

    // Second loop to insert spaces between assets or move asset
    for (int i = 1; i < layers[layerIndex].assets.length; i++) {
      Asset asset = layers[layerIndex].assets[i];
      Asset prevAsset = layers[layerIndex].assets[i - 1];
      if ((asset.begin ?? 0) >
          ((prevAsset.begin ?? 0) + (prevAsset.duration ?? 0))) {
        Asset newAsset = Asset(
          type: AssetType.text,
          begin: (prevAsset.begin ?? 0) + (prevAsset.duration ?? 0),
          duration:
              (asset.begin ?? 0) -
              ((prevAsset.begin ?? 0) + (prevAsset.duration ?? 0)),
          title: '',
          srcPath: '',
        );
        layers[layerIndex].assets.insert(i, newAsset);
      } else {
        asset.begin = (prevAsset.begin ?? 0) + (prevAsset.duration ?? 0);
      }
    }
    if (layers[layerIndex].assets.isNotEmpty &&
        (layers[layerIndex].assets[0].begin ?? 0) > 0) {
      Asset newAsset = Asset(
        type: AssetType.text,
        begin: 0,
        duration: layers[layerIndex].assets[0].begin ?? 0,
        title: '',
        srcPath: '',
      );
      layers[layerIndex].assets.insert(0, newAsset);
    }

    // Last space until video duration
    if (layers[layerIndex].assets.last.title == '') {
      layers[layerIndex].assets.last.duration =
          duration - (layers[layerIndex].assets.last.begin ?? 0);
    } else {
      Asset prevAsset = layers[layerIndex].assets.last;
      Asset asset = Asset(
        type: AssetType.text,
        begin: (prevAsset.begin ?? 0) + (prevAsset.duration ?? 0),
        duration:
            duration - ((prevAsset.begin ?? 0) + (prevAsset.duration ?? 0)),
        title: '',
        srcPath: '',
      );
      layers[layerIndex].assets.add(asset);
    }
  }

  _addAssetToLayer(int layerIndex, AssetType type, String srcPath) async {
    _ensureDefaultLayers();
    if (layerIndex >= layers.length) {
      // Optionally, add more layers if needed (should not happen with default 3 layers)
      return;
    }
    print('_addAssetToLayer: $srcPath');

    int assetDuration;
    if (type == AssetType.video || type == AssetType.audio) {
      // TODO: Replace with actual video/audio duration logic
      assetDuration = 5000;
    } else {
      assetDuration = 5000;
    }

    layers[layerIndex].assets.add(
      Asset(
        type: type,
        srcPath: srcPath,
        title: p.basename(srcPath),
        duration: assetDuration,
        begin: layers[layerIndex].assets.isEmpty
            ? 0
            : (layers[layerIndex].assets.last.begin ?? 0) +
                  (layers[layerIndex].assets.last.duration ?? 0),
      ),
    );

    // Always re-initialize layerPlayers[0] after adding a video asset
    if (type == AssetType.video && layers[0].assets.isNotEmpty) {
      if (layerPlayers.length < 1) {
        layerPlayers.length = 1;
      }
      if (layerPlayers[0] != null) {
        await layerPlayers[0]!.dispose();
      }
      layerPlayers[0] = LayerPlayer(layers[0]);
      await layerPlayers[0]!.initialize();
      layerPlayers[0]!.currentAssetIndex = layers[0].assets.length - 1;
    }

    _layersChanged.add(true);
    _appBar.add(true);
  }

  select(int layerIndex, int assetIndex) async {
    if (isOperating) return;
    if (layerIndex == 1 && layers[layerIndex].assets[assetIndex].title == '') {
      _selected.add(Selected(-1, -1));
    } else {
      _selected.add(Selected(layerIndex, assetIndex));
    }
    _appBar.add(true);
  }

  dragStart(layerIndex, assetIndex) {
    if (isOperating) return;
    if (layerIndex == 1 && layers[layerIndex].assets[assetIndex].title == '')
      return;
    isDragging = true;
    Selected sel = Selected(layerIndex, assetIndex);
    sel.initScrollOffset = scrollController.offset;
    _selected.add(sel);
    _appBar.add(true);
  }

  dragSelected(
    int layerIndex,
    int assetIndex,
    double dragX,
    double scrollWidth,
  ) {
    if (layerIndex == 1 && layers[layerIndex].assets[assetIndex].title == '')
      return;
    Asset assetSelected = layers[layerIndex].assets[assetIndex];
    int closest = assetIndex;
    int pos =
        (assetSelected.begin ?? 0) +
        ((dragX + scrollController.offset - selected.initScrollOffset) /
                pixelsPerSecond *
                1000)
            .floor();
    if (dragX + scrollController.offset - selected.initScrollOffset < 0) {
      closest = getClosestAssetIndexLeft(layerIndex, assetIndex, pos);
    } else {
      pos = pos + (assetSelected.duration ?? 0);
      closest = getClosestAssetIndexRight(layerIndex, assetIndex, pos);
    }
    updateScrollOnDrag(pos, scrollWidth);
    Selected sel = Selected(
      layerIndex,
      assetIndex,
      dragX: dragX,
      closestAsset: closest,
      initScrollOffset: selected.initScrollOffset,
      incrScrollOffset: scrollController.offset - selected.initScrollOffset,
    );
    _selected.add(sel);
  }

  updateScrollOnDrag(int pos, double scrollWidth) {
    double outOfScrollRight =
        pos * pixelsPerSecond / 1000 -
        scrollController.offset -
        scrollWidth / 2;
    double outOfScrollLeft =
        scrollController.offset -
        pos * pixelsPerSecond / 1000 -
        scrollWidth / 2 +
        32; // Layer header width: 32
    if (outOfScrollRight > 0 && outOfScrollLeft < 0) {
      scrollController.animateTo(
        scrollController.offset + math.min(outOfScrollRight, 50),
        duration: Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    }
    if (outOfScrollRight < 0 && outOfScrollLeft > 0) {
      scrollController.animateTo(
        scrollController.offset - math.min(outOfScrollLeft, 50),
        duration: Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    }
  }

  int getClosestAssetIndexLeft(int layerIndex, int assetIndex, int pos) {
    int closest = assetIndex;
    int distance = (pos - (layers[layerIndex].assets[assetIndex].begin ?? 0))
        .abs();
    if (assetIndex < 1) return assetIndex;
    for (int i = assetIndex - 1; i >= 0; i--) {
      int d = (pos - (layers[layerIndex].assets[i].begin ?? 0)).abs();
      if (d < distance) {
        closest = i;
        distance = d;
      }
    }
    return closest;
  }

  int getClosestAssetIndexRight(int layerIndex, int assetIndex, int pos) {
    int closest = assetIndex;
    int endAsset =
        (layers[layerIndex].assets[assetIndex].begin ?? 0) +
        (layers[layerIndex].assets[assetIndex].duration ?? 0);
    int distance = (pos - endAsset).abs();
    if (assetIndex >= layers[layerIndex].assets.length - 1) return assetIndex;
    for (int i = assetIndex + 1; i < layers[layerIndex].assets.length; i++) {
      int end =
          (layers[layerIndex].assets[i].begin ?? 0) +
          (layers[layerIndex].assets[i].duration ?? 0);
      layers[layerIndex].assets[i].duration;
      int d = (pos - end).abs();
      if (d < distance) {
        closest = i;
        distance = d;
      }
    }
    return closest;
  }

  dragEnd() async {
    if (selected.layerIndex != 1) {
      await exchange();
    } else {
      moveTextAsset();
    }
    isDragging = false;
    _appBar.add(true);
  }

  exchange() async {
    int layerIndex = selected.layerIndex;
    int assetIndex1 = selected.assetIndex;
    int assetIndex2 = selected.closestAsset;
    // Reset selected before
    _selected.add(Selected(-1, -1));

    if (layerIndex == -1 ||
        assetIndex1 == -1 ||
        assetIndex2 == -1 ||
        assetIndex1 == assetIndex2)
      return;

    Asset asset1 = layers[layerIndex].assets[assetIndex1];

    layers[layerIndex].assets.removeAt(assetIndex1);
    // No removeMediaSource in standard video_player API

    layers[layerIndex].assets.insert(assetIndex2, asset1);
    // No addMediaSource in standard video_player API

    refreshCalculatedFieldsInAssets(layerIndex, 0);
    _layersChanged.add(true);

    // Delayed 100 because it seems updating mediaSources is not immediate
    Future.delayed(Duration(milliseconds: 100), () async {
      await _previewOnPosition();
    });
  }

  moveTextAsset() {
    int layerIndex = selected.layerIndex;
    int assetIndex = selected.assetIndex;
    if (layerIndex == -1 || assetIndex == -1) return;

    int pos =
        (assetSelected?.begin ?? 0) +
        ((selected.dragX +
                    scrollController.offset -
                    selected.initScrollOffset) /
                pixelsPerSecond *
                1000)
            .floor();

    // Reset selected before
    _selected.add(Selected(-1, -1));

    layers[layerIndex].assets[assetIndex].begin = math.max(pos, 0);
    reorganizeTextAssets(layerIndex);
    _layersChanged.add(true);
    _previewOnPosition();
  }

  cutVideo() async {
    if (isOperating) return;
    if (selected.layerIndex == -1 || selected.assetIndex == -1) return;
    print('>> DirectorService.cutVideo()');
    final Asset assetAfter =
        layers[selected.layerIndex].assets[selected.assetIndex];
    final int diff = position - (assetAfter.begin ?? 0);
    if (diff <= 0 || diff >= (assetAfter.duration ?? 0)) return;
    isCutting = true;

    final Asset assetBefore = Asset.clone(assetAfter);
    layers[selected.layerIndex].assets.insert(selected.assetIndex, assetBefore);

    assetBefore.duration = diff;
    assetAfter.begin = assetBefore.begin! + diff;
    assetAfter.cutFrom = assetBefore.cutFrom! + diff;
    assetAfter.duration = assetAfter.duration! - diff;

    // No removeMediaSource in standard video_player API
    // No addMediaSource in standard video_player API

    _layersChanged.add(true);

    if (assetAfter.type == AssetType.video) {
      assetAfter.thumbnailPath = null;
      // TODO: Generate video thumbnails if needed
    }

    _selected.add(Selected(-1, -1));
    _appBar.add(true);

    // Delayed blocking 300 because it seems updating mediaSources is not immediate
    // because preview can fail
    Future.delayed(Duration(milliseconds: 300), () {
      isCutting = false;
    });
  }

  delete() {
    if (isOperating) return;
    if (selected.layerIndex == -1 || selected.assetIndex == -1) return;
    print('>> DirectorService.delete()');
    isDeleting = true;
    AssetType? type = assetSelected?.type;
    layers[selected.layerIndex].assets.removeAt(selected.assetIndex);
    // No removeMediaSource in standard video_player API
    if (type != AssetType.text) {
      refreshCalculatedFieldsInAssets(selected.layerIndex, selected.assetIndex);
    }
    _layersChanged.add(true);

    _selected.add(Selected(-1, -1));

    _filesNotExist.add(checkSomeFileNotExists());
    reorganizeTextAssets(1);

    isDeleting = false;

    if (position > duration) {
      _position.add(duration);
      scrollController.jumpTo(duration / 1000 * pixelsPerSecond);
    }
    _layersChanged.add(true);
    _appBar.add(true);
    // TODO: remove thumbnails not used

    // Delayed because it seems updating mediaSources is not immediate
    Future.delayed(Duration(milliseconds: 100), () {
      _previewOnPosition();
    });
  }

  refreshCalculatedFieldsInAssets(int layerIndex, int assetIndex) {
    for (int i = assetIndex; i < layers[layerIndex].assets.length; i++) {
      layers[layerIndex].assets[i].begin = (i == 0)
          ? 0
          : (layers[layerIndex].assets[i - 1].begin ?? 0) +
                (layers[layerIndex].assets[i - 1].duration ?? 0);
    }
  }

  scaleStart() {
    if (isOperating) return;
    isScaling = true;
    _selected.add(Selected(-1, -1));
    _pixelsPerSecondOnInitScale = pixelsPerSecond;
    _scrollOffsetOnInitScale = scrollController.offset;
  }

  scaleUpdate(double scale) {
    if (!isScaling || _pixelsPerSecondOnInitScale == null) return;
    double pixPerSecond = _pixelsPerSecondOnInitScale! * scale;
    pixPerSecond = math.min(pixPerSecond, 100);
    pixPerSecond = math.max(pixPerSecond, 1);
    _pixelsPerSecond.add(pixPerSecond);
    _layersChanged.add(true);
    scrollController.jumpTo(
      (_scrollOffsetOnInitScale! * pixPerSecond) / _pixelsPerSecondOnInitScale!,
    );
  }

  scaleEnd() {
    isScaling = false;
    _layersChanged.add(true);
  }

  Asset? getAssetByPosition(int layerIndex) {
    for (int i = 0; i < layers[layerIndex].assets.length; i++) {
      final asset = layers[layerIndex].assets[i];
      final begin = asset.begin ?? 0;
      final duration = asset.duration ?? 0;
      if (begin + duration - 1 >= position) {
        return asset;
      }
    }
    return null;
  }

  sizerDragStart(bool sizerEnd) {
    if (isOperating) return;
    isSizerDragging = true;
    isSizerDraggingEnd = sizerEnd;
    dxSizerDrag = 0;
  }

  sizerDragUpdate(bool sizerEnd, double dx) {
    dxSizerDrag += dx;
    _selected.add(selected); // To refresh UI
  }

  sizerDragEnd(bool sizerEnd) async {
    await executeSizer(sizerEnd);
    _selected.add(selected); // To refresh UI
    dxSizerDrag = 0;
    isSizerDragging = false;
  }

  executeSizer(bool sizerEnd) async {
    Asset? asset = assetSelected;
    if (asset == null) return;
    if (asset.type == AssetType.text || asset.type == AssetType.image) {
      int dxSizerDragMillis = (dxSizerDrag / pixelsPerSecond * 1000).floor();
      if (!isSizerDraggingEnd) {
        if ((asset.begin ?? 0) + dxSizerDragMillis < 0) {
          dxSizerDragMillis = -(asset.begin ?? 0);
        }
        if ((asset.duration ?? 0) - dxSizerDragMillis < 1000) {
          dxSizerDragMillis = (asset.duration ?? 0) - 1000;
        }
        asset.begin = (asset.begin ?? 0) + dxSizerDragMillis;
        asset.duration = (asset.duration ?? 0) - dxSizerDragMillis;
      } else {
        if ((asset.duration ?? 0) + dxSizerDragMillis < 1000) {
          dxSizerDragMillis = -(asset.duration ?? 0) + 1000;
        }
        asset.duration = (asset.duration ?? 0) + dxSizerDragMillis;
      }
      if (asset.type == AssetType.text) {
        reorganizeTextAssets(1);
      } else if (asset.type == AssetType.image) {
        refreshCalculatedFieldsInAssets(
          selected.layerIndex,
          selected.assetIndex,
        );
        // No removeMediaSource/addMediaSource in standard video_player API
      }
      _selected.add(Selected(-1, -1));
    }
    _layersChanged.add(true);
  }

  // generateVideo removed (generator and VideoResolution undefined)

  _deleteThumbnailsNotUsed() async {
    // TODO: pending to implement
    // TODO: implement thumbnail cleanup if needed
  }
}
