// lib/widgets/audio_message.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

import 'package:photocrew/widgets/audio_player_manager.dart';

class AudioMessageWidget extends StatefulWidget {
  final String? audioUrl;
  final bool isCurrentUser;

  const AudioMessageWidget({
    super.key,
    this.audioUrl,
    required this.isCurrentUser,
  });

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final _audioManager = AudioPlayerManager();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    if (widget.audioUrl == null) return;

    try {
      _durationSubscription =
          _audioManager.player.durationStream.listen((duration) {
        if (mounted) {
          setState(() => _duration = duration ?? Duration.zero);
        }
      });

      _positionSubscription =
          _audioManager.player.positionStream.listen((position) {
        if (mounted && _audioManager.currentlyPlayingUrl == widget.audioUrl) {
          setState(() => _position = position);
        }
      });

      _playerStateSubscription =
          _audioManager.player.playerStateStream.listen((state) {
        if (mounted) {
          final isThisAudioPlaying =
              _audioManager.currentlyPlayingUrl == widget.audioUrl;

          setState(() {
            _isPlaying = state.playing && isThisAudioPlaying;

            if (state.processingState == ProcessingState.completed &&
                isThisAudioPlaying) {
              _position = _duration;
              _isPlaying = false;
              _audioManager.stop(); // Ensure cleanup after completion
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  Future<void> _handlePlayPause() async {
    if (widget.audioUrl == null) return;

    setState(() => _isLoading = true);
    try {
      if (_isPlaying) {
        await _audioManager.pause();
      } else {
        // If this audio was previously played and completed
        if (_position >= _duration && _duration > Duration.zero) {
          _position = Duration.zero;
        }
        await _audioManager.playAudio(widget.audioUrl!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final bool isActiveAudio =
        _audioManager.currentlyPlayingUrl == widget.audioUrl;
    final double progress = _duration.inMilliseconds > 0
        ? (isActiveAudio ? _position.inMilliseconds : 0) /
            _duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  widget.isCurrentUser
                      ? Theme.of(context).brightness == Brightness.light
                          ? Colors.white
                          : Colors.black
                      : Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isCurrentUser
                    ? Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Colors.black
                    : Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
              ),
              onPressed: _handlePlayPause,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: widget.isCurrentUser
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        widget.isCurrentUser
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(
                          isActiveAudio ? _position : Duration.zero),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isCurrentUser
                            ? Theme.of(context).brightness == Brightness.light
                                ? Colors.white70
                                : Colors.black54
                            : Theme.of(context).brightness == Brightness.light
                                ? Colors.black54
                                : Colors.white70,
                      ),
                    ),
                    Text(
                      ' / ${_formatDuration(_duration)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isCurrentUser
                            ? Theme.of(context).brightness == Brightness.light
                                ? Colors.white70
                                : Colors.black54
                            : Theme.of(context).brightness == Brightness.light
                                ? Colors.black54
                                : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    if (_audioManager.currentlyPlayingUrl == widget.audioUrl) {
      _audioManager.stop();
    }
    super.dispose();
  }
}
