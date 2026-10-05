import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

/// Video player built on video_player + chewie controls.
class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key, required this.path});

  final String path;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final VideoPlayerController video = VideoPlayerController.file(File(widget.path));
    try {
      await video.initialize();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) {
      await video.dispose();
      return;
    }
    setState(() {
      _video = video;
      _chewie = ChewieController(
        videoPlayerController: video,
        autoPlay: true,
        looping: false,
        allowPlaybackSpeedChanging: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: context.colors.primaryContainer,
          handleColor: context.colors.primaryContainer,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );
    });
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: FvAppBar(
        backgroundColor: Colors.black,
        leading: const FvBackButton(),
        title: p.basename(widget.path),
      ),
      body: Center(
        child: _failed
            ? FvEmptyState(
                icon: Icons.videocam_off_outlined,
                title: context.l10n.cannotPlay,
                message: context.l10n.noAppToOpen,
              )
            : _chewie == null
                ? const CircularProgressIndicator()
                : Chewie(controller: _chewie!),
      ),
    );
  }
}
