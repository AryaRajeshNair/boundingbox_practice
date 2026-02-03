import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../models/boundingbox_logic.dart';
import 'annotation_screen.dart';

class AnnotationQueueScreen extends StatefulWidget {
  final List<XFile>? images;
  final List<Uint8List>? videoFrames;
  final List<ObjectClass> classes;
  final String? videoName;

  const AnnotationQueueScreen({
    this.images,
    this.videoFrames,
    required this.classes,
    this.videoName,
  })  : assert(images != null || videoFrames != null,
            'Either images or videoFrames must be provided');

  @override
  State<AnnotationQueueScreen> createState() => _AnnotationQueueScreenState();
}

class _AnnotationQueueScreenState extends State<AnnotationQueueScreen> {
  late int currentIndex = 0;

  bool get _isVideoMode => widget.videoFrames != null;
  int get _itemCount => _isVideoMode ? widget.videoFrames!.length : widget.images!.length;

  String _getFilenameWithoutExtension(String imagePath) {
    return imagePath.split('/').last.split('.').first;
  }

  void _goToNextImage() {
    if (currentIndex < _itemCount - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      // Finished all images
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All items annotated!')),
      );
      Navigator.pop(context);
    }
  }

  void _goToPreviousImage() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  void _annotateCurrentImage() {
    if (_isVideoMode) {
      final frameName = '${widget.videoName} - Frame ${currentIndex + 1}';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnnotationScreen(
            imageData: widget.videoFrames![currentIndex],
            imageName: frameName,
            classes: widget.classes,
          ),
        ),
      );
    } else {
      final currentImage = widget.images![currentIndex];
      final imageName = _getFilenameWithoutExtension(currentImage.path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnnotationScreen(
            imagePath: currentImage.path,
            imageName: imageName,
            classes: widget.classes,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isVideoMode
        ? 'Frame ${currentIndex + 1} of ${_itemCount}'
        : 'Image ${currentIndex + 1} of ${_itemCount}';
    
    final displayName = _isVideoMode 
        ? '${widget.videoName} - Frame ${currentIndex + 1}'
        : _getFilenameWithoutExtension(widget.images![currentIndex].path);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Display frame/image
                      if (_isVideoMode)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            widget.videoFrames![currentIndex],
                            width: 300,
                            height: 300,
                            fit: BoxFit.contain,
                          ),
                        )
                      else
                        Icon(
                          Icons.image,
                          size: 80,
                          color: Colors.deepPurple.withValues(alpha: 0.5),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _isVideoMode ? 'Frame Name:' : 'Image Name:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_isVideoMode) ...[
                        Text(
                          'Full Path:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.images![currentIndex].path,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else
                        Text(
                          'Video: ${widget.videoName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.file_present, color: Colors.blue),
                            const SizedBox(width: 8),
                            
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(height: 24),

                
                Column(
                  children: [
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _annotateCurrentImage,
                        icon: const Icon(Icons.edit),
                        label: const Text('Annotate This Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                currentIndex > 0 ? _goToPreviousImage : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Previous'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: currentIndex < _itemCount - 1
                                ? _goToNextImage
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Done (Exit)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
