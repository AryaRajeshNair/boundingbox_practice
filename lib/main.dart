import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_probe/video_probe.dart';
import 'screens/annotation_queue_screen.dart';
import 'models/boundingbox_logic.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLO Annotator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _imagePicker = ImagePicker();
  late List<ObjectClass> objectClasses;
  List<XFile> _selectedImages = [];
  List<Uint8List>? _videoFrames;
  String? _selectedVideoName;

  @override
  void initState() {
    super.initState();
    
    objectClasses = [
      ObjectClass(id: 0, name: 'person', color: Colors.red),
      ObjectClass(id: 1, name: 'car', color: Colors.blue),
      ObjectClass(id: 2, name: 'dog', color: Colors.green),
      ObjectClass(id: 3, name: 'cat', color: Colors.yellow),
    ];
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
        _navigateToAnnotationQueue();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final probe = VideoProbe();
        
        // Get video duration and frame count
        await probe.getDuration(video.path);
        final frameCount = await probe.getFrameCount(video.path);
        
        // Extract frames at evenly spaced intervals (6 frames total)
        final List<Uint8List> frames = [];
        final int frameInterval = (frameCount / 6).toInt();
        
        for (int i = 1; i <= 6; i++) {
          final int frameIndex = frameInterval * i;
          if (frameIndex < frameCount) {
            try {
              final jpegBytes = await probe.extractFrame(video.path, frameIndex);
              if (jpegBytes != null) {
                frames.add(jpegBytes);
              }
            } catch (e) {
              print('Error extracting frame at index $frameIndex: $e');
            }
          }
        }

        setState(() {
          _videoFrames = frames;
          _selectedVideoName = video.name;
        });

        if (mounted && frames.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Extracted ${frames.length} frames from video')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    }
  }

  void _navigateToAnnotationQueue() {
    if (_selectedImages.isEmpty && (_videoFrames == null || _videoFrames!.isEmpty)) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (_videoFrames != null && _videoFrames!.isNotEmpty) {
            return AnnotationQueueScreen(
              videoFrames: _videoFrames,
              classes: objectClasses,
              videoName: _selectedVideoName,
            );
          } else {
            return AnnotationQueueScreen(
              images: _selectedImages,
              classes: objectClasses,
            );
          }
        },
      ),
    );
  }



  void _showClassManagement() {
    showDialog(
      context: context,
      builder: (context) => _ClassManagementDialog(
        classes: objectClasses,
        onClassesChanged: (newClasses) {
          setState(() {
            objectClasses = newClasses;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLO Annotator'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showClassManagement,
            tooltip: 'Manage Classes',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_library),
                    label: const Text('Pick Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Display extracted video frames
                if (_videoFrames != null && _videoFrames!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extracted Frames from: $_selectedVideoName',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _videoFrames!.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _videoFrames![index],
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Frame ${index + 1}'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToAnnotationQueue,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Annotate Frames'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Object Classes (${objectClasses.length}):',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton.icon(
                            onPressed: _showClassManagement,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: objectClasses
                            .map(
                              (cls) => Chip(
                                label: Text(cls.name),
                                backgroundColor: cls.color.withValues(alpha: 0.3),
                                labelStyle: TextStyle(
                                  color: cls.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassManagementDialog extends StatefulWidget {
  final List<ObjectClass> classes;
  final Function(List<ObjectClass>) onClassesChanged;

  const _ClassManagementDialog({
    required this.classes,
    required this.onClassesChanged,
  });

  @override
  State<_ClassManagementDialog> createState() => _ClassManagementDialogState();
}

class _ClassManagementDialogState extends State<_ClassManagementDialog> {
  late List<ObjectClass> editingClasses;
  late TextEditingController _classNameController;
  Map<int, TextEditingController> _editControllers = {};

  static const List<Color> availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    editingClasses = List.from(widget.classes);
    _classNameController = TextEditingController();
  }

  @override
  void dispose() {
    _classNameController.dispose();
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addClass() {
    if (_classNameController.text.trim().isNotEmpty) {
      setState(() {
        editingClasses.add(
          ObjectClass(
            id: editingClasses.length,
            name: _classNameController.text.trim(),
            color: availableColors[editingClasses.length % availableColors.length],
          ),
        );
      });
      _classNameController.clear();
    }
  }

  void _removeClass(int index) {
    setState(() {
      editingClasses.removeAt(index);
      
      for (int i = 0; i < editingClasses.length; i++) {
        editingClasses[i] = ObjectClass(
          id: i,
          name: editingClasses[i].name,
          color: editingClasses[i].color,
        );
      }
    });
  }

  void _editClassName(int index) {
    final controller = TextEditingController(text: editingClasses[index].name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Class Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                editingClasses[index] = ObjectClass(
                  id: editingClasses[index].id,
                  name: value.trim(),
                  color: editingClasses[index].color,
                );
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  editingClasses[index] = ObjectClass(
                    id: editingClasses[index].id,
                    name: controller.text.trim(),
                    color: editingClasses[index].color,
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _changeColor(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableColors
              .map(
                (color) => GestureDetector(
                  onTap: () {
                    setState(() {
                      editingClasses[index] = ObjectClass(
                        id: editingClasses[index].id,
                        name: editingClasses[index].name,
                        color: color,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: editingClasses[index].color == color
                            ? Colors.black
                            : Colors.grey,
                        width: editingClasses[index].color == color ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('Manage Classes'),
          const Spacer(),
          Text(
            '${editingClasses.length} classes',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _classNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter class name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      prefixIcon: Icon(Icons.add),
                    ),
                    onSubmitted: (_) => _addClass(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addClass,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            Flexible(
              child: editingClasses.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No classes yet.\nAdd your first class above!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: editingClasses.length,
                      itemBuilder: (context, index) {
                        final cls = editingClasses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () => _changeColor(index),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: cls.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey, width: 2),
                                ),
                                child: const Icon(
                                  Icons.palette,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            title: Text(
                              cls.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('ID: ${cls.id}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _editClassName(index),
                                  tooltip: 'Edit name',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _removeClass(index),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onClassesChanged(editingClasses);
            Navigator.pop(context);
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
