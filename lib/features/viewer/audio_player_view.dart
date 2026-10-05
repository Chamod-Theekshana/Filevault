import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

/// Audio player with a queue built from the files in the same folder.
class AudioPlayerView extends StatefulWidget {
  const AudioPlayerView({super.key, required this.queue, required this.initialIndex});

  final List<FileEntry> queue;
  final int initialIndex;

  @override
  State<AudioPlayerView> createState() => _AudioPlayerViewState();
}

class _AudioPlayerViewState extends State<AudioPlayerView> {
  final AudioPlayer _player = AudioPlayer();
  int _index = 0;
  bool _failed = false;
  bool _shuffle = false;
  LoopMode _loop = LoopMode.off;

  @override
  void initState() {
    super.initState();
    _index =
        widget.queue.isEmpty ? 0 : widget.initialIndex.clamp(0, widget.queue.length - 1);
    if (widget.queue.isEmpty) {
      _failed = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      await _player.setAudioSources(
        <AudioSource>[
          for (final FileEntry e in widget.queue) AudioSource.file(e.path),
        ],
        initialIndex: _index,
      );
      _player.currentIndexStream.listen((int? i) {
        if (i != null && mounted) setState(() => _index = i);
      });
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  FileEntry? get _currentOrNull => widget.queue.isEmpty
      ? null
      : widget.queue[_index.clamp(0, widget.queue.length - 1)];

  String _fmt(Duration d) {
    final String m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final FileEntry? current = _currentOrNull;
    final Brightness b = Theme.of(context).brightness;
    if (_failed || current == null) {
      return Scaffold(
        appBar: FvAppBar(
          leading: const FvBackButton(),
          title: current == null ? context.l10n.nowPlaying : p.basename(current.path),
        ),
        body: FvEmptyState(
          icon: Icons.music_off_outlined,
          title: context.l10n.cannotPlay,
          message: context.l10n.noAppToOpen,
        ),
      );
    }
    final FileEntry entry = current;
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: context.l10n.nowPlaying,
        subtitle: context.l10n.fromFolder(p.basename(entry.parentPath)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + context.padding.bottom),
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    CategoryColors.ink(b, FileCategory.audio).withValues(alpha: 0.35),
                    context.colors.primaryContainer.withValues(alpha: 0.55),
                  ],
                ),
                boxShadow: <BoxShadow>[context.tokens.ambientShadow],
              ),
              child: Center(
                child: Icon(
                  Icons.graphic_eq,
                  size: 96,
                  color: context.colors.onPrimary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            entry.stem,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.texts.headlineMedium,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              FvChip(
                label: '${entry.extension.toUpperCase()} • ${FileSizeFormatter.format(entry.size)}',
                icon: Icons.audiotrack,
                dense: true,
              ),
              if (widget.queue.length > 1)
                FvChip(
                  label: context.l10n.ofCount(_index + 1, widget.queue.length),
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (BuildContext context, AsyncSnapshot<Duration> snap) {
              final Duration position = snap.data ?? Duration.zero;
              final Duration total = _player.duration ?? Duration.zero;
              final double max = total.inMilliseconds.toDouble();
              return Column(
                children: <Widget>[
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    ),
                    child: Slider(
                      value: max == 0 ? 0 : position.inMilliseconds.clamp(0, max.toInt()).toDouble(),
                      max: max == 0 ? 1 : max,
                      onChanged: (double v) => _player.seek(Duration(milliseconds: v.round())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(_fmt(position), style: context.texts.labelMedium),
                        Text(
                          total == Duration.zero ? '--:--' : '-${_fmt(total - position)}',
                          style: context.texts.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.shuffle, color: _shuffle ? context.colors.primary : null),
                onPressed: () async {
                  setState(() => _shuffle = !_shuffle);
                  await _player.setShuffleModeEnabled(_shuffle);
                },
              ),
              IconButton(
                iconSize: 34,
                icon: const Icon(Icons.skip_previous),
                onPressed: _player.hasPrevious ? _player.seekToPrevious : null,
              ),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (BuildContext context, AsyncSnapshot<PlayerState> snap) {
                  final bool playing = snap.data?.playing ?? false;
                  final bool buffering = snap.data?.processingState == ProcessingState.buffering ||
                      snap.data?.processingState == ProcessingState.loading;
                  return SizedBox(
                    width: 72,
                    height: 72,
                    child: Material(
                      color: context.colors.primaryContainer,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => playing ? _player.pause() : _player.play(),
                        child: buffering
                            ? const Padding(
                                padding: EdgeInsets.all(22),
                                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                              )
                            : Icon(
                                playing ? Icons.pause : Icons.play_arrow,
                                size: 36,
                                color: context.colors.onPrimary,
                              ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                iconSize: 34,
                icon: const Icon(Icons.skip_next),
                onPressed: _player.hasNext ? _player.seekToNext : null,
              ),
              IconButton(
                icon: Icon(
                  _loop == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                  color: _loop == LoopMode.off ? null : context.colors.primary,
                ),
                onPressed: () async {
                  final LoopMode next = switch (_loop) {
                    LoopMode.off => LoopMode.all,
                    LoopMode.all => LoopMode.one,
                    LoopMode.one => LoopMode.off,
                  };
                  setState(() => _loop = next);
                  await _player.setLoopMode(next);
                },
              ),
            ],
          ),
          if (widget.queue.length > 1) ...<Widget>[
            const SizedBox(height: 20),
            FvSectionHeader(
              title: context.l10n.upNext,
              uppercase: false,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            ),
            FvCard(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < widget.queue.length; i++)
                    ListTile(
                      leading: FvCategoryTile(
                        category: FileCategory.audio,
                        size: 40,
                        icon: i == _index ? Icons.graphic_eq : Icons.music_note_outlined,
                      ),
                      title: Text(
                        widget.queue[i].stem,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: i == _index
                            ? context.texts.titleSmall?.copyWith(color: context.colors.primary)
                            : context.texts.titleSmall,
                      ),
                      subtitle: Text(FileSizeFormatter.format(widget.queue[i].size)),
                      onTap: () => _player.seek(Duration.zero, index: i),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
