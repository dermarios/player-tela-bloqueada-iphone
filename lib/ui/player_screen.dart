import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../main.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Tela Bloqueada'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album artwork
            StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;
                return Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: mediaItem?.artUri != null
                        ? Image.file(
                            File(mediaItem!.artUri!.toFilePath()),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const _PlaceholderArtwork(),
                          )
                        : const _PlaceholderArtwork(),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),

            // Title and artist
            StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;
                return Column(
                  children: [
                    Text(
                      mediaItem?.title ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mediaItem?.artist ?? 'Unknown Artist',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),

            // Progress bar and time
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final position = state?.updatePosition ?? Duration.zero;
                final duration = audioHandler.mediaItem.value?.duration ?? Duration.zero;

                return Column(
                  children: [
                    Slider(
                      min: 0,
                      max: duration.inMilliseconds.toDouble(),
                      value: position.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        audioHandler.seek(
                          Duration(milliseconds: value.toInt()),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),

            // Controls
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final playing = state?.playing ?? false;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 40,
                      onPressed: audioHandler.skipToPrevious,
                    ),
                    const SizedBox(width: 24),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: playing
                            ? audioHandler.pause
                            : audioHandler.play,
                        child: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 40,
                      onPressed: audioHandler.skipToNext,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _PlaceholderArtwork extends StatelessWidget {
  const _PlaceholderArtwork({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 120,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }
}
