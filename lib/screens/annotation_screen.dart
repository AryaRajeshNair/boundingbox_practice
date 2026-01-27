import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import '../models/boundingbox_logic.dart';
import '../painters/annotation_painter.dart';

class AnnotationScreen extends StatefulWidget {
  final String imagePath;
  final String imageName; 
  final List<ObjectClass> classes;

  const AnnotationScreen({
    super.key,
    required this.imagePath,
    required this.imageName,
    required this.classes,
  });

  @override
  State<AnnotationScreen> createState() => _AnnotationScreenState();
}

class _AnnotationScreenState extends State<AnnotationScreen> {
  late List<BoundingBox> boxes = [];
  Color currentColor = Colors.red;
  late int selectedClassId = widget.classes.isNotEmpty ? widget.classes[0].id : 0;
  Offset? startPoint;
  Offset? endPoint;
  late Size imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    boxes = [];
  }

  void _updateSelectedClass(int classId) {
    final selectedClass = widget.classes.firstWhere(
      (c) => c.id == classId,
      orElse: () => widget.classes[0],
    );
    setState(() {
      selectedClassId = classId;
      currentColor = selectedClass.color;
    });
  }

  void _startBox(Offset point) {
    setState(() {
      startPoint = point;
      endPoint = point;
    });
  }

  void _updateBox(Offset point) {
    setState(() {
      endPoint = point;
    });
  }

  void _endBox() {
    if (startPoint != null && endPoint != null) {
      final start = startPoint!;
      final end = endPoint!;

      
      if ((end.dx - start.dx).abs() > 5 && (end.dy - start.dy).abs() > 5) {
        final selectedClass = widget.classes.firstWhere(
          (c) => c.id == selectedClassId,
          orElse: () => widget.classes[0],
        );

        setState(() {
          boxes.add(
            BoundingBox(
              topLeft: Offset(
                start.dx < end.dx ? start.dx : end.dx,
                start.dy < end.dy ? start.dy : end.dy,
              ),
              bottomRight: Offset(
                start.dx > end.dx ? start.dx : end.dx,
                start.dy > end.dy ? start.dy : end.dy,
              ),
              className: selectedClass.name,
              classId: selectedClassId,
              color: selectedClass.color,
            ),
          );
          startPoint = null;
          endPoint = null;
        });
      } else {
        setState(() {
          startPoint = null;
          endPoint = null;
        });
      }
    }
  }

  void _deleteLastBox() {
    setState(() {
      if (boxes.isNotEmpty) {
        boxes.removeLast();
      }
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Boxes'),
        content: const Text('Are you sure you want to clear all bounding boxes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                boxes.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _saveAnnotations() {
    
    final annotations = boxes
        .map((box) => box.toYolo(imageSize.width, imageSize.height).toString())
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
          ),
          TextButton(
        onPressed: () async {
          await _downloadAnnotations(annotations);
        },
        child: const Text('Download labels'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'boxes': boxes,
                'annotations': annotations,
                'imagePath': widget.imagePath,
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAnnotations(List<String> annotations) async {
    try {
      final content = annotations.join('\n');
      final bytes = Uint8List.fromList(content.codeUnits);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final filename = '${widget.imageName}.txt';
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: $filename'),
            duration: const Duration(seconds: 2),
          ),
        );
        
        Navigator.pop(context);
        Navigator.pop(context, {
          'boxes': boxes,
          'annotations': annotations,
          'imagePath': widget.imagePath,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading file: $e')),
        );
      }
    }
  }

  String _generateClassSummary() {
    final classCounts = <String, int>{};
    for (var box in boxes) {
      classCounts[box.className] = (classCounts[box.className] ?? 0) + 1;
    }
    return classCounts.entries
        .map((e) => '  ${e.key}: ${e.value}')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annotate for YOLO'),
        elevation: 0,
      ),
      body: Column(
        children: [
          
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (details) {
                    _startBox(details.localPosition);
                  },
                  onPanUpdate: (details) {
                    _updateBox(details.localPosition);
                  },
                  onPanEnd: (details) {
                    _endBox();
                  },
                  child: Container(
                    color: Colors.grey[200],
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (imageSize == Size.zero) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  imageSize = Size(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  );
                                });
                              });
                            }
                            return Image.network(
                              widget.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text('Error loading image: $error'),
                                );
                              },
                            );
                          },
                        ),
                        // Annotation canvas
                        CustomPaint(
                          painter: AnnotationPainter(
                            boxes: boxes,
                            currentStart: startPoint,
                            currentEnd: endPoint,
                            currentBoxColor: currentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Class:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: widget.classes
                              .map(
                                (cls) => FilterChip(
                                  label: Text(cls.name),
                                  selected: selectedClassId == cls.id,
                                  backgroundColor: cls.color.withValues(alpha: 0.3),
                                  selectedColor: cls.color,
                                  onSelected: (selected) {
                                    _updateSelectedClass(cls.id);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Annotations: ${boxes.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (boxes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _generateClassSummary(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _deleteLastBox,
                          icon: const Icon(Icons.undo),
                          label: const Text('Undo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.delete),
                          label: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveAnnotations,
                          icon: const Icon(Icons.check),
                          label: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
