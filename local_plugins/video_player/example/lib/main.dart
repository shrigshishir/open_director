// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Controls play and pause of [controller].
///
/// Toggles play/pause on tap (accompanied by a fading status icon).
///
/// Plays (looping) on initialization, and mutes on deactivation.

class VideoPlayPause extends StatefulWidget {
  const VideoPlayPause(this.controller, {Key? key}) : super(key: key);

  final VideoPlayerController controller;

  @override
  State<VideoPlayPause> createState() => _VideoPlayPauseState();
}

class _VideoPlayPauseState extends State<VideoPlayPause> {
  late FadeAnimation imageFadeAnim;
  late VoidCallback listener;

  VideoPlayerController get controller => widget.controller;

  @override
  @override
  void initState() {
    super.initState();
    imageFadeAnim =
        FadeAnimation(child: const Icon(Icons.play_arrow, size: 100.0));
    listener = () {
      setState(() {});
    };
    controller.addListener(listener);
    controller.setVolume(1.0);
    controller.play();
  }

  @override
  void deactivate() {
    controller.setVolume(0.0);
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      GestureDetector(
        child: VideoPlayer(controller),
        onTap: () {
          if (!controller.value.initialized) {
            return;
          }
          if (controller.value.isPlaying) {
            imageFadeAnim =
                FadeAnimation(child: const Icon(Icons.pause, size: 100.0));
            controller.pause();
          } else {
            imageFadeAnim =
                FadeAnimation(child: const Icon(Icons.play_arrow, size: 100.0));
            controller.play();
          }
        },
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: VideoProgressIndicator(
          controller,
          allowScrubbing: true,
        ),
      ),
      Center(child: imageFadeAnim),
      Center(
          child: controller.value.isBuffering
              ? const CircularProgressIndicator()
              : null),
    ];

    return Stack(
      fit: StackFit.passthrough,
      children: children,
    );
  }
}

class FadeAnimation extends StatefulWidget {
  const FadeAnimation(
      {required this.child,
      this.duration = const Duration(milliseconds: 500),
      Key? key})
      : super(key: key);

  final Widget child;
  final Duration duration;

  @override
  _FadeAnimationState createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(duration: widget.duration, vsync: this);
    animationController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    animationController.forward(from: 0.0);
  }

  @override
  void deactivate() {
    animationController.stop();
    super.deactivate();
  }

  @override
  void didUpdateWidget(FadeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return animationController.isAnimating
        ? Opacity(
            opacity: 1.0 - animationController.value,
            child: widget.child,
          )
        : Container();
  }
}

typedef VideoWidgetBuilder = Widget Function(
    BuildContext context, VideoPlayerController controller);

abstract class PlayerLifeCycle extends StatefulWidget {
  const PlayerLifeCycle(this.dataSource, this.childBuilder, {Key? key})
      : super(key: key);

  final VideoWidgetBuilder childBuilder;
  final String dataSource;
}

/// A widget connecting its life cycle to a [VideoPlayerController] using
/// a data source from the network.
class NetworkPlayerLifeCycle extends PlayerLifeCycle {
  NetworkPlayerLifeCycle(String dataSource, VideoWidgetBuilder childBuilder)
      : super(dataSource, childBuilder);

  @override
  _NetworkPlayerLifeCycleState createState() => _NetworkPlayerLifeCycleState();
}

/// A widget connecting its life cycle to a [VideoPlayerController] using
/// an asset as data source
class AssetPlayerLifeCycle extends PlayerLifeCycle {
  AssetPlayerLifeCycle(String dataSource, VideoWidgetBuilder childBuilder)
      : super(dataSource, childBuilder);

  @override
  _AssetPlayerLifeCycleState createState() => _AssetPlayerLifeCycleState();
}

abstract class _PlayerLifeCycleState extends State<PlayerLifeCycle> {
  late VideoPlayerController controller;

  @override

  /// Subclasses should implement [createVideoPlayerController], which is used
  /// by this method.
  void initState() {
    super.initState();
    controller = createVideoPlayerController();
    controller.addListener(() {
      if (controller.value.hasError) {
        print(controller.value.errorDescription);
      }
    });
    controller.initialize();
    controller.setLooping(true);
    controller.play();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.childBuilder(context, controller);
  }

  VideoPlayerController createVideoPlayerController();
}

class _NetworkPlayerLifeCycleState extends _PlayerLifeCycleState {
  @override
  VideoPlayerController createVideoPlayerController() {
    return VideoPlayerController.network(widget.dataSource);
  }
}

class _AssetPlayerLifeCycleState extends _PlayerLifeCycleState {
  @override
  VideoPlayerController createVideoPlayerController() {
    return VideoPlayerController.asset(widget.dataSource);
  }
}

/// A filler card to show the video in a list of scrolling contents.

Widget buildCard(String title) {
  return Card(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.airline_seat_flat_angled),
          title: Text(title),
        ),
        ButtonBar(
          children: <Widget>[
            TextButton(
              child: const Text('BUY TICKETS'),
              onPressed: () {
                /* ... */
              },
            ),
            TextButton(
              child: const Text('SELL TICKETS'),
              onPressed: () {
                /* ... */
              },
            ),
          ],
        ),
      ],
    ),
  );
}

class VideoInListOfCards extends StatelessWidget {
  const VideoInListOfCards(this.controller, {Key? key}) : super(key: key);

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        buildCard("Item a"),
        buildCard("Item b"),
        buildCard("Item c"),
        buildCard("Item d"),
        buildCard("Item e"),
        buildCard("Item f"),
        buildCard("Item g"),
        Card(
            child: Column(children: <Widget>[
          Column(
            children: <Widget>[
              const ListTile(
                leading: Icon(Icons.cake),
                title: Text("Video video"),
              ),
              Stack(
                  alignment: FractionalOffset.bottomRight +
                      const FractionalOffset(-0.1, -0.1),
                  children: <Widget>[
                    AspectRatioVideo(controller),
                    Image.asset('assets/flutter-mark-square-64.png'),
                  ]),
            ],
          ),
        ])),
        buildCard("Item h"),
        buildCard("Item i"),
        buildCard("Item j"),
        buildCard("Item k"),
        buildCard("Item l"),
      ],
    );
  }
}

class AspectRatioVideo extends StatefulWidget {
  const AspectRatioVideo(this.controller, {Key? key}) : super(key: key);

  final VideoPlayerController controller;

  @override
  AspectRatioVideoState createState() => AspectRatioVideoState();
}

class AspectRatioVideoState extends State<AspectRatioVideo> {
  VideoPlayerController get controller => widget.controller;
  bool initialized = false;

  late VoidCallback listener;

  @override
  void initState() {
    super.initState();
    listener = () {
      if (!mounted) {
        return;
      }
      if (initialized != controller.value.initialized) {
        initialized = controller.value.initialized;
        setState(() {});
      }
    };
    controller.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (initialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayPause(controller),
        ),
      );
    } else {
      return Container();
    }
  }
}

void main() {
  runApp(
    MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Video player example'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: <Widget>[
                Tab(
                  icon: Icon(Icons.cloud),
                  text: "Remote",
                ),
                Tab(icon: Icon(Icons.insert_drive_file), text: "Asset"),
                Tab(icon: Icon(Icons.list), text: "List example"),
              ],
            ),
          ),
          body: TabBarView(
            children: <Widget>[
              SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 20.0),
                    ),
                    const Text('With remote m3u8'),
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: NetworkPlayerLifeCycle(
                        'http://184.72.239.149/vod/smil:BigBuckBunny.smil/playlist.m3u8',
                        (BuildContext context,
                                VideoPlayerController controller) =>
                            AspectRatioVideo(controller),
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 20.0),
                    ),
                    const Text('With assets mp4'),
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: AssetPlayerLifeCycle(
                          'assets/Butterfly-209.mp4',
                          (BuildContext context,
                                  VideoPlayerController controller) =>
                              AspectRatioVideo(controller)),
                    ),
                  ],
                ),
              ),
              AssetPlayerLifeCycle(
                  'assets/Butterfly-209.mp4',
                  (BuildContext context, VideoPlayerController controller) =>
                      VideoInListOfCards(controller)),
            ],
          ),
        ),
      ),
    ),
  );
}
