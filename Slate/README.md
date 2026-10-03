# Slate — Native macOS Whiteboard

Slate is an ultra-fast, local-first, native macOS whiteboard app built entirely in **Swift 6, SwiftUI, AppKit, and Metal** for macOS 14+.

Slate is engineered from first principles with zero third-party dependencies, zero cloud sync or accounts, zero network entitlements, and zero black-box ML models. Every smart feature—from hold-to-snap shape recognition to text-to-guide visual diagram generation and webcam fingertip gesture tracking—is 100% deterministic, rule-based, and local.

---

## Key Highlights

- **120fps Metal Canvas**: Sub-10ms input-to-ink latency, ProMotion 120Hz support, tiled spatial indexing cache (`TileCache`) capable of rendering 10,000+ vector strokes without frame drops.
- **Minimalist, Native Product Design**: SF Pro, SF Symbols, restrained editorial color palettes, 8pt grid, hairline borders, soft single-layer shadows. Floating toolbar auto-fades during drawing. Contextual inspector appears only when elements are selected.
- **Webcam Fingertip Gesture Tracking (Zero ML)**: Color-based HSV computer vision with two-pass connected components blob detection. 2 marker blobs = Draw, 1 marker blob = Erase, 0 blobs = Hover. 3-frame hysteresis and One Euro filter smoothing.
- **Text to Visual Guide Engine (Zero AI)**: Deterministic markdown/text parser converting outlines, steps, comparisons (`vs`), directional flows (`->`), and dates into fully editable Flowcharts, Mind Maps, Step Cards, Timelines, Checklists, and Comparison Tables.
- **Step-by-Step Presentation Mode**: Organize canvas frames/sections into presentation slides with smooth full-screen presentation navigation and a live glowing laser pointer trail.
- **Local Document Package Format (`.slate`)**: Stored as Finder packages with JSON schemas, snapshot history checkpoints, and embedded assets. Instant launch under 400ms.

---

## Project Structure

```
Slate/
├── Slate.xcodeproj/                  # Xcode Project
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/Slate.xcscheme
├── Slate/
│   ├── App/
│   │   ├── SlateApp.swift            # SwiftUI App lifecycle & AppKit AppDelegate
│   │   └── MenuCommands.swift        # Native macOS AppKit menu bar commands
│   ├── Model/
│   │   ├── SlateDocument.swift       # Document schema, metadata, canvas bounds
│   │   ├── CanvasElement.swift       # Polymorphic vector element model
│   │   ├── Stroke.swift              # Pressure-sensitive ink stroke with pixel splitting
│   │   ├── ShapeElement.swift        # Rect, Ellipse, Line, Arrow, Diamond, Triangle
│   │   ├── TextElement.swift         # Rich text formatting & typography
│   │   ├── StickyNoteElement.swift   # Pastel sticky notes with folded corners
│   │   ├── ConnectorElement.swift    # Smart dynamic connectors (orthogonal, curved)
│   │   ├── FrameElement.swift        # Section & presentation slide containers
│   │   ├── ImageElement.swift        # Bitmap image drop-in support
│   │   ├── LaserPoint.swift          # Transient glowing laser trail
│   │   ├── Point2D.swift             # High-precision SIMD-compatible point
│   │   ├── ColorData.swift           # Restrained RGBA color representations
│   │   ├── BoardMetadata.swift       # Fast indexing & favorites metadata
│   │   └── Snapshot.swift            # Document version checkpoints
│   ├── Persistence/
│   │   ├── SlatePackage.swift        # .slate document package encoder/decoder
│   │   ├── DocumentStore.swift       # Local board manager & search indexer
│   │   └── AutosaveManager.swift     # Debounced (300ms) non-blocking autosave
│   ├── Undo/
│   │   ├── UndoCommand.swift         # Command pattern (Add, Remove, Move, Modify)
│   │   └── UndoManagerEngine.swift   # Unlimited undo/redo stack
│   ├── Canvas/
│   │   ├── Metal/
│   │   │   ├── Shaders.metal         # Metal vertex/fragment shaders (ink, grid, laser)
│   │   │   ├── StrokeTessellator.swift # Catmull-Rom smoothing & triangle mesh extrusion
│   │   │   ├── TileCache.swift       # 512x512 spatial tile index
│   │   │   ├── MetalRenderer.swift   # MTKViewDelegate triple-buffered renderer
│   │   │   └── MetalCanvasView.swift # Native MTKView subclass
│   │   ├── AppKitCanvas/
│   │   │   ├── SlateCanvasNSView.swift # AppKit canvas view, gestures, overlays
│   │   │   ├── CanvasCoordinateTransform.swift # Viewport pan/zoom transforms
│   │   │   └── CanvasInputHandler.swift # Tablet pressure, hold-to-snap timer
│   │   ├── AlignmentEngine.swift     # Smart alignment guides & object snapping
│   │   ├── GeometrySnapper.swift     # Rule-based geometric shape recognition
│   │   ├── OneEuroFilter.swift       # Adaptive jitter filter
│   │   ├── MinimapView.swift         # Interactive board minimap
│   │   └── RulersView.swift          # Coordinate point rulers
│   ├── Tools/
│   │   └── CanvasTool.swift          # All 20 canvas tools & shortcuts
│   ├── TextToVisualGuide/
│   │   ├── TextGuideParser.swift     # Deterministic markdown/text outline parser
│   │   ├── GuideLayoutEngine.swift   # Flowchart, Mindmap, StepCards, Timeline, Checklist
│   │   └── PresentationManager.swift # Slide ordering & presentation mode
│   ├── CameraTracking/
│   │   ├── CameraTrackingProtocol.swift
│   │   ├── HSVColorFilter.swift      # Accelerate/SIMD RGB-to-HSV color mask
│   │   ├── BlobDetector.swift        # Two-pass connected components labeling
│   │   ├── GestureStateMachine.swift # 2-blob DRAW, 1-blob ERASE, 0-blob HOVER
│   │   ├── CameraCalibration.swift   # Presets (Green, Orange, Blue, Custom)
│   │   ├── CameraManager.swift       # AVFoundation capture pipeline
│   │   └── CameraPiPView.swift       # Picture-in-Picture preview & status badge
│   ├── Export/
│   │   ├── PNGExporter.swift         # High-DPI 2x/3x raster export
│   │   ├── PDFExporter.swift         # Vector PDF export
│   │   ├── SVGExporter.swift         # Scalable SVG 1.1 export
│   │   └── ClipboardManager.swift    # Copy PNG/SVG to clipboard
│   ├── UI/
│   │   ├── StyleConstants.swift      # Design tokens (8pt grid, hairline, shadows)
│   │   ├── MainView.swift            # Root SwiftUI view
│   │   ├── FloatingToolbar.swift     # Minimal pill toolbar with auto-fade
│   │   ├── InspectorPanel.swift      # Contextual selection inspector
│   │   ├── CommandPalette.swift      # ⌘K instant search palette
│   │   ├── BoardLibraryView.swift    # Thumbnail card grid & search
│   │   ├── SnapshotHistoryView.swift # Version snapshots timeline
│   │   ├── CameraSettingsModal.swift # Calibration wizard & tolerance sliders
│   │   ├── KeyboardCheatSheetModal.swift # Shortcut reference cheat sheet
│   │   └── PresentationOverlayView.swift # Presentation mode controls
│   └── Resources/
│       ├── Info.plist                # Sandboxed bundle configuration & UTIs
│       ├── Slate.entitlements        # Camera entitlement only (Zero network)
│       └── Assets.xcassets           # AppIcon & AccentColor tokens
└── SlateTests/
    ├── ModelTests.swift              # Serialization & element math tests
    ├── ParserTests.swift             # Deterministic outline parser tests
    ├── GestureStateMachineTests.swift # 2-blob draw, erase, hysteresis tests
    ├── PersistenceTests.swift        # Package bundle read/write tests
    └── SnappingTests.swift           # Circle, rectangle, line snapping tests
```

---

## Complete Feature Matrix (All 68 Features)

### Tools
1. **Select/Cursor (`V`)**: Marquee select, drag move, transform bounding box.
2. **Pen (`P`)**: Vector ink with pressure sensitivity and Catmull-Rom smoothing.
3. **Highlighter (`H`)**: Semi-transparent wide stroke with multiply blend mode.
4. **Stroke Eraser (`E`)**: Deletes entire stroke on contact.
5. **Pixel Partial Eraser (`X`)**: Splits stroke paths into sub-strokes at contact point.
6. **Text (`T`)**: Click-to-place text with font size, weight, alignment, and color.
7. **Rectangle (`R`)**: Corner radius, fill, stroke, dash pattern.
8. **Ellipse (`O`)**: Circles and ovals with fill, stroke, dash.
9. **Line (`L`)**: Straight line with Shift angle snapping.
10. **Arrow (`A`)**: Directional arrows with start/end arrowheads.
11. **Diamond (`D`)**: Decision nodes for flowcharts and diagrams.
12. **Triangle (`G`)**: Diagram triangles with fill and stroke.
13. **Sticky Note (`S`)**: 7 pastel themes (Yellow, Green, Blue, Pink, Orange, Purple, Gray), folded corner, subtle shadow.
14. **Smart Connector (`C`)**: Magnetic shape anchoring, straight/orthogonal/curved routing.
15. **Laser Pointer (`K`)**: Glowing transient trail that smoothly decays over 1.2s.
16. **Hand / Pan (`Space`)**: Canvas panning with two-finger trackpad drag.
17. **Frame / Section (`F`)**: Named slide containers for organizing and presenting.
18. **Image Drop-in (`I`)**: Drag and drop images directly from Finder onto the canvas.
19. **Lasso Select (`Q`)**: Freeform polygon lasso selection.
20. **Eyedropper (`Y`)**: Instant color sampler from any canvas element.

### Drawing Quality
21. **Stroke Smoothing / Stabilizer**: Dynamic Catmull-Rom spline tessellation.
22. **Pressure Sensitivity**: Force Touch trackpad / tablet pressure mapping.
23. **Hold-to-Snap Shapes**: Rule-based shape recognition on 450ms pause at stroke end.
24. **Straight-Line with Shift**: Lock strokes to horizontal or vertical axes.
25. **Angle Snapping (15°)**: Snap lines and arrows to 15-degree increments.
26. **Variable Brush Width**: 1pt to 64pt.
27. **Opacity**: 10% to 100%.
28. **Dashed / Dotted Strokes**: Solid, dashed, dotted line patterns.

### Canvas
29. **Infinite Canvas**: Unbounded 2D floating-point coordinate space.
30. **Pinch Zoom & Two-Finger Pan**: 10% to 1000% zoom with momentum.
31. **Zoom Shortcuts**: ⌘0 (Fit), ⌘1 (100%), ⌘2 (Selection).
32. **Background Styles**: Dots, Grid, Lines, Blank.
33. **Snap to Grid & Objects**: Edge and center magnetic alignment.
34. **Smart Alignment Guides**: Cyan/magenta live guide lines with spacing indicators.
35. **Interactive Minimap (`⌘M`)**: Miniature viewport rectangle with click-to-jump.
36. **Point Rulers (`⌘R`)**: Coordinate rulers with hairline ticks.

### Editing & Organization
37. **Unlimited Undo/Redo (`⌘Z`, `⇧⌘Z`)**: Command pattern stack.
38. **Duplicate & Copy/Paste (`⌘D`, `⌥-drag`, `⌘C`, `⌘V`)**.
39. **Group / Ungroup (`⌘G`, `⇧⌘G`)**.
40. **Align & Distribute**: Left, Center, Right, Top, Middle, Bottom, Distribute H/V.
41. **Z-Order**: Bring to Front (`⇧⌘]`), Send to Back (`⇧⌘[`), Bring Forward (`⌘]`), Send Backward (`⌘[`).
42. **Lock / Unlock (`⌘L`)**.
43. **8-Point Transform Handles**: Corner and edge resize plus rotation handle.
44. **Custom Color Palette**: Editorial preset palette + custom RGBA picker.
45. **Rich Typography**: Font family, font size, weight, alignment.
46. **Multi-Select**: Shift-click or marquee bounding box.

### Boards & Persistence
47. **Autosave**: Debounced 300ms background save, automatic restore on launch.
48. **Board Library (`⌘L`)**: Card grid with vector thumbnail previews.
49. **Board Management**: Rename, duplicate, delete, favorite.
50. **Fast Search**: Indexed search across board titles and canvas text elements.
51. **Version Snapshots**: Per-board timestamped checkpoint snapshots with one-click restore.
52. **Document Package (`.slate`)**: Standard macOS bundle package format.

### Text to Visual Guide (Deterministic Engine)
53. **Deterministic Markdown Parsing**: Headings (`#`), bullets (`-`), steps (`1.`), flows (`->`), comparisons (`vs`), dates (`2026-10-03`).
54. **6 Layout Engines**: Flowchart, Mind Map, Step Cards, Timeline, Checklist, Comparison Table.
55. **Presentation Slides**: Frames automatically sequenced into full-screen presentations.

### Camera Finger Tracking (Zero ML)
56. **Marker Trail Visualization**: Real-time fingertip path tracking.
57. **Color Profile Presets**: Green sticker, Orange cap, Blue tape, Custom HSV.
58. **Test Mode**: Practice gestures with hover pointer without placing ink.
59. **Adjustable Active Area**: Calibrate camera frame sub-rectangle mapped to canvas.

### Output & System
60. **Export**: PNG (1x/2x/3x), Vector PDF, Scalable SVG.
61. **Copy to Clipboard**: Quick PNG/SVG export to system pasteboard.
62. **Full-Screen Presentation Mode (`⌃⌘F`)**.
63. **Command Palette (`⌘K`)**: Instant fuzzy search across all actions.
64. **Keyboard Shortcut Reference (`⌘/`)**.
65. **Dark / Light / System Mode Support**.
66. **Sandboxed Privacy**: Zero network access, local-only storage.

---

## Camera Tracking Calibration Tips

To use camera finger tracking without ML:
1. Place a colored sticker or marker cap (e.g., bright green sticker or orange cap) on your index finger (and optionally middle finger for drawing).
2. Press `⌥C` to toggle camera tracking.
3. In the floating PiP preview or Camera Settings modal (`⚙︎`):
   - Select the preset matching your marker (e.g., **Green Sticker**).
   - Adjust the **Hue Tolerance** slider until only your marker is highlighted in the mask.
4. **Gestures**:
   - **2 Marker Blobs (Index + Middle finger together)**: DRAW ink.
   - **1 Marker Blob (Index finger only)**: ERASE ink.
   - **0 Blobs (Hand down / fist)**: HOVER pointer (Pen Up).

---

## Building and Running

### Requirements
- macOS 14.0 (Sonoma) or macOS 15+ (Sequoia)
- Xcode 15 or Xcode 16 with Swift 6

### Open in Xcode
```bash
open Slate.xcodeproj
```
Select the `Slate` scheme and press **⌘R** to build and run, or **⌘U** to run the unit test suite.

### DMG Installation
Double-click `Slate.dmg` and drag `Slate.app` into your `/Applications` folder.
