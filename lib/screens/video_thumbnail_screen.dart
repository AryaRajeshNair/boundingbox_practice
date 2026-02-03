import 'package:flutter/material.dart';
import 'dart:io';

class VideoThumbnailScreen extends StatelessWidget {
  final String videoPath;
  final String? thumbnailPath;
  final String videoName;

  const VideoThumbnailScreen({
    super.key,
    required this.videoPath,
    required this.thumbnailPath,
    required this.videoName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Thumbnail'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (thumbnailPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(thumbnailPath!),
                    width: 320,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 320,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Thumbnail not available'),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Video: $videoName',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
