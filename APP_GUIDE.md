# Image Annotation App - Architecture & Features

## How It Works

### Architecture Overview

The app is organized into several key components:

1. **HomePage** - Main entry screen
   - Allows users to pick images from camera or gallery
   - Shows app features and navigation

2. **AnnotationScreen** - Main annotation interface
   - Displays uploaded image with annotation canvas on top
   - Handles all drawing interactions
   - Provides tools panel with controls

3. **AnnotationPainter** - CustomPaint renderer
   - Draws all strokes, shapes, and text labels on canvas
   - Handles different drawing types (pen, rectangle, circle)

4. **Models** - Data structures
   - `DrawingStroke`: Represents a single drawing stroke
   - `TextLabel`: Represents text annotations

### Drawing Tools

- **Pen**: Freehand drawing with smooth strokes
- **Box**: Draw bounding boxes/rectangles
- **Circle**: Draw circular annotations
- **Text**: Add text labels at any position

### Features

✅ Image Selection (Camera or Gallery)
✅ Freehand Drawing
✅ Bounding Box Drawing
✅ Circle Drawing
✅ Text Labels
✅ Color Selection (8 colors)
✅ Brush Size Control (1-20px)
✅ Undo Functionality
✅ Clear All Annotations
✅ Save/Complete Annotations

### File Structure

```
lib/
├── main.dart                    # App entry & home screen
├── models/
│   └── drawing_stroke.dart      # Data models
├── painters/
│   └── annotation_painter.dart  # CustomPaint renderer
└── screens/
    └── annotation_screen.dart   # Main annotation interface
```

## How to Use the App

1. **Launch App** → Home screen appears
2. **Pick Image** → Choose "Take Photo" or "Choose from Gallery"
3. **Annotate Image** → 
   - Select a tool (Pen, Box, Circle, Text)
   - Choose color and brush size
   - Draw on the image
4. **Manage Annotations** →
   - Use Undo to remove last annotation
   - Use Clear to remove all annotations
5. **Complete** → Press "Done" to finish

## Technologies Used

- **image_picker**: For camera and gallery access
- **Flutter CustomPaint**: For drawing on canvas
- **Material Design 3**: UI/UX components
- **Dart/Flutter**: Development framework

## Future Enhancement Ideas

1. **Save Annotations** - Export annotated image
2. **Redo Functionality** - Redo undone actions
3. **Shape Presets** - Arrows, lines, triangles
4. **Eraser Tool** - Remove specific drawings
5. **Layers** - Organize annotations in layers
6. **Templates** - Pre-defined annotation templates
7. **Batch Processing** - Annotate multiple images
8. **Cloud Sync** - Save annotations to cloud
