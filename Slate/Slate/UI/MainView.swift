//
//  MainView.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI
#if canImport(AppKit)
import AppKit

public struct CanvasRepresentable: NSViewRepresentable {
    @Binding public var document: SlateDocument
    @Binding public var selectedElementIDs: Set<UUID>
    public var activeTool: CanvasTool
    public var strokeColor: ColorData
    public var strokeWidth: Double
    public var opacity: Double
    public var isDarkMode: Bool
    public var onDocumentChanged: (SlateDocument) -> Void
    public var onSelectionChanged: (Set<UUID>) -> Void
    public var onColorSampled: (ColorData) -> Void
    
    public func makeNSView(context: Context) -> SlateCanvasNSView {
        let view = SlateCanvasNSView(frame: .zero)
        view.document = document
        view.selectedElementIDs = selectedElementIDs
        view.activeTool = activeTool
        view.currentStrokeColor = strokeColor
        view.currentStrokeWidth = strokeWidth
        view.currentOpacity = opacity
        view.isDarkMode = isDarkMode
        view.onDocumentChanged = onDocumentChanged
        view.onSelectionChanged = onSelectionChanged
        view.onColorSampled = onColorSampled
        return view
    }
    
    public func updateNSView(_ nsView: SlateCanvasNSView, context: Context) {
        nsView.document = document
        nsView.selectedElementIDs = selectedElementIDs
        nsView.activeTool = activeTool
        nsView.currentStrokeColor = strokeColor
        nsView.currentStrokeWidth = strokeWidth
        nsView.currentOpacity = opacity
        nsView.isDarkMode = isDarkMode
    }
}
#endif

public struct MainView: View {
    @StateObject public var documentStore: DocumentStore = .shared
    @StateObject public var undoManager: UndoManagerEngine = UndoManagerEngine()
    @StateObject public var cameraManager: CameraManager = .shared
    @StateObject public var presentationManager: PresentationManager = .shared
    
    @State public var document: SlateDocument = SlateDocument()
    @State public var selectedElementIDs: Set<UUID> = []
    
    @State public var activeTool: CanvasTool = .pen
    @State public var strokeColor: ColorData = .ink
    @State public var fillColor: ColorData = .clear
    @State public var strokeWidth: Double = 3.0
    @State public var opacity: Double = 1.0
    @State public var cornerRadius: Double = 8.0
    @State public var fontSize: Double = 18.0
    @State public var isDrawing: Bool = false
    
    @State public var showCommandPalette: Bool = false
    @State public var showBoardLibrary: Bool = false
    @State public var showSnapshotHistory: Bool = false
    @State public var showCameraSettings: Bool = false
    @State public var showCheatSheet: Bool = false
    @State public var showVisualGuideDialog: Bool = false
    @State public var guideTextPrompt: String = "# Project Plan\n1. Architecture & Metal Canvas\n2. Camera Finger Tracking\n3. Text to Guide Engine"
    @State public var selectedGuideLayout: GuideLayoutType = .flowchart
    
    @Environment(\.colorScheme) var colorScheme
    
    public init() {}
    
    public var body: some View {
        ZStack {
            #if canImport(AppKit)
            // Canvas View
            CanvasRepresentable(
                document: $document,
                selectedElementIDs: $selectedElementIDs,
                activeTool: activeTool,
                strokeColor: strokeColor,
                strokeWidth: strokeWidth,
                opacity: opacity,
                isDarkMode: colorScheme == .dark,
                onDocumentChanged: { updatedDoc in
                    self.document = updatedDoc
                    AutosaveManager.shared.scheduleSave(document: updatedDoc)
                },
                onSelectionChanged: { newSel in
                    self.selectedElementIDs = newSel
                },
                onColorSampled: { sampled in
                    self.strokeColor = sampled
                }
            )
            .edgesIgnoringSafeArea(.all)
            #endif
            
            // Rulers Overlay
            if document.showRulers {
                RulersView(
                    offset: CGPoint(x: document.viewportOffset.x, y: document.viewportOffset.y),
                    zoom: CGFloat(document.viewportZoom),
                    isDarkMode: colorScheme == .dark
                )
                .allowsHitTesting(false)
            }
            
            // Top Controls Bar (Board Title, Background Style, Presentation, Command Palette)
            VStack {
                topNavigationBar
                Spacer()
                // Bottom Floating Toolbar
                if !presentationManager.isPresenting {
                    FloatingToolbar(
                        activeTool: $activeTool,
                        strokeColor: $strokeColor,
                        strokeWidth: $strokeWidth,
                        opacity: $opacity,
                        canUndo: undoManager.canUndo,
                        canRedo: undoManager.canRedo,
                        onUndo: { undoManager.undo(on: &document) },
                        onRedo: { undoManager.redo(on: &document) },
                        onToggleLibrary: { showBoardLibrary.toggle() },
                        onToggleCamera: {
                            if cameraManager.isTrackingEnabled {
                                cameraManager.stopTracking()
                            } else {
                                cameraManager.startTracking()
                            }
                        },
                        isCameraActive: cameraManager.isTrackingEnabled,
                        isDrawing: isDrawing
                    )
                    .padding(.bottom, 20)
                }
            }
            
            // Contextual Inspector Panel (Top-Right)
            if !selectedElementIDs.isEmpty && !presentationManager.isPresenting {
                VStack {
                    HStack {
                        Spacer()
                        InspectorPanel(
                            strokeColor: $strokeColor,
                            fillColor: $fillColor,
                            strokeWidth: $strokeWidth,
                            opacity: $opacity,
                            cornerRadius: $cornerRadius,
                            fontSize: $fontSize,
                            selectedCount: selectedElementIDs.count,
                            isLocked: isSelectionLocked,
                            onAlignLeft: { alignSelected(mode: .left) },
                            onAlignCenter: { alignSelected(mode: .centerX) },
                            onAlignRight: { alignSelected(mode: .right) },
                            onAlignTop: { alignSelected(mode: .top) },
                            onAlignMiddle: { alignSelected(mode: .centerY) },
                            onAlignBottom: { alignSelected(mode: .bottom) },
                            onDistributeH: { distributeSelected(horizontal: true) },
                            onDistributeV: { distributeSelected(horizontal: false) },
                            onBringToFront: { changeZOrder(toFront: true) },
                            onSendToBack: { changeZOrder(toBack: true) },
                            onBringForward: { changeZOrder(step: 1) },
                            onSendBackward: { changeZOrder(step: -1) },
                            onToggleLock: { toggleSelectionLock() },
                            onDuplicate: { duplicateSelected() },
                            onDelete: { deleteSelected() },
                            onMakeGuide: { showVisualGuideDialog = true }
                        )
                        .padding(.top, 56)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
            }
            
            // Minimap (Bottom-Right)
            if document.showMinimap && !presentationManager.isPresenting {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        MinimapView(document: $document) { navOffset in
                            document.viewportOffset = navOffset
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            
            // Camera PiP Preview (Bottom-Left)
            if cameraManager.isTrackingEnabled && !presentationManager.isPresenting {
                VStack {
                    Spacer()
                    HStack {
                        CameraPiPView {
                            showCameraSettings = true
                        }
                        .padding(.leading, 16)
                        .padding(.bottom, 16)
                        Spacer()
                    }
                }
            }
            
            // Full Screen Presentation Overlay
            if presentationManager.isPresenting {
                VStack {
                    Spacer()
                    PresentationOverlayView(presentationManager: presentationManager) {
                        presentationManager.endPresentation()
                    }
                    .padding(.bottom, 24)
                }
            }
            
            // Modal Overlays
            if showCommandPalette {
                Color.black.opacity(0.2).edgesIgnoringSafeArea(.all).onTapGesture { showCommandPalette = false }
                CommandPalette(isPresented: $showCommandPalette, commands: buildCommands())
            }
            
            if showBoardLibrary {
                Color.black.opacity(0.3).edgesIgnoringSafeArea(.all).onTapGesture { showBoardLibrary = false }
                BoardLibraryView(
                    onSelectBoard: { id in
                        if let loaded = documentStore.loadBoard(id: id) {
                            self.document = loaded
                            self.selectedElementIDs = []
                        }
                        showBoardLibrary = false
                    },
                    onClose: { showBoardLibrary = false }
                )
            }
            
            if showSnapshotHistory {
                Color.black.opacity(0.2).edgesIgnoringSafeArea(.all).onTapGesture { showSnapshotHistory = false }
                SnapshotHistoryView(
                    document: $document,
                    onClose: { showSnapshotHistory = false },
                    onRestore: { snap in
                        _ = document.restoreSnapshot(snap)
                        showSnapshotHistory = false
                    }
                )
            }
            
            if showCameraSettings {
                Color.black.opacity(0.2).edgesIgnoringSafeArea(.all).onTapGesture { showCameraSettings = false }
                CameraSettingsModal { showCameraSettings = false }
            }
            
            if showCheatSheet {
                Color.black.opacity(0.2).edgesIgnoringSafeArea(.all).onTapGesture { showCheatSheet = false }
                KeyboardCheatSheetModal { showCheatSheet = false }
            }
            
            if showVisualGuideDialog {
                Color.black.opacity(0.3).edgesIgnoringSafeArea(.all).onTapGesture { showVisualGuideDialog = false }
                visualGuideDialog
            }
        }
        .onAppear {
            if let active = documentStore.activeDocument {
                self.document = active
            } else if let first = documentStore.boards.first, let loaded = documentStore.loadBoard(id: first.id) {
                self.document = loaded
            } else {
                let newDoc = documentStore.createNewBoard(title: "Main Canvas")
                self.document = newDoc
            }
        }
    }
    
    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack(spacing: 8) {
            // Board Title
            TextField("Untitled Board", text: $document.metadata.title)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: 180)
            
            Divider().frame(height: 16)
            
            // Grid Background Selector
            Picker("Grid", selection: $document.gridStyle) {
                ForEach(GridStyle.allCases, id: \.self) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.small)
            .frame(width: 220)
            
            // Toggle Rulers & Minimap
            Button(action: { document.showRulers.toggle() }) {
                Image(systemName: "ruler")
                    .foregroundColor(document.showRulers ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Rulers (⌘R)")
            
            Button(action: { document.showMinimap.toggle() }) {
                Image(systemName: "map")
                    .foregroundColor(document.showMinimap ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Minimap (⌘M)")
            
            Spacer()
            
            // Text to Visual Guide Button
            Button(action: { showVisualGuideDialog = true }) {
                Label("Make Visual Guide", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            // Presentation Button
            Button(action: {
                presentationManager.startPresentation(document: document)
            }) {
                Label("Present", systemImage: "play.fill")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
            // Snapshots / Version History
            Button(action: { showSnapshotHistory.toggle() }) {
                Image(systemName: "clock.arrow.circlepath")
            }
            .buttonStyle(.plain)
            .help("Version Snapshots")
            
            // Keyboard Cheat Sheet
            Button(action: { showCheatSheet.toggle() }) {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.plain)
            .help("Keyboard Shortcuts (⌘/)")
            
            // Command Palette (⌘K)
            Button(action: { showCommandPalette.toggle() }) {
                HStack(spacing: 3) {
                    Image(systemName: "magnifyingglass")
                    Text("⌘K").font(.system(size: 10, design: .monospaced))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Visual Guide Modal Dialog
    private var visualGuideDialog: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Text to Visual Guide", systemImage: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button(action: { showVisualGuideDialog = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            
            Text("Paste text notes, outlines, or steps below. Deterministic rule-based layout generator creates editable canvas shapes.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            TextEditor(text: $guideTextPrompt)
                .font(.system(size: 12, design: .monospaced))
                .frame(height: 140)
                .padding(4)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Layout Style Picker
            Picker("Layout Option:", selection: $selectedGuideLayout) {
                ForEach(GuideLayoutType.allCases) { layout in
                    Text(layout.rawValue).tag(layout)
                }
            }
            .pickerStyle(.segmented)
            
            HStack {
                Spacer()
                Button("Cancel") { showVisualGuideDialog = false }
                Button("Generate Diagram") {
                    let parsed = TextGuideParser.parse(text: guideTextPrompt)
                    let elements = GuideLayoutEngine.generateLayout(
                        type: selectedGuideLayout,
                        parsedDoc: parsed,
                        origin: Point2D(x: 150, y: 150)
                    )
                    for el in elements {
                        document.addElement(el)
                    }
                    AutosaveManager.shared.scheduleSave(document: document)
                    showVisualGuideDialog = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
    
    // MARK: - Helper Actions
    private var isSelectionLocked: Bool {
        selectedElementIDs.contains { id in
            document.element(with: id)?.isLocked ?? false
        }
    }
    
    private func toggleSelectionLock() {
        let lockState = !isSelectionLocked
        for id in selectedElementIDs {
            if var el = document.element(with: id) {
                el.isLocked = lockState
                document.updateElement(el)
            }
        }
    }
    
    private func duplicateSelected() {
        var newIds = Set<UUID>()
        for id in selectedElementIDs {
            if let el = document.element(with: id) {
                let shifted = el.translated(by: CGPoint(x: 30, y: 30))
                document.addElement(shifted)
                newIds.insert(shifted.id)
            }
        }
        selectedElementIDs = newIds
    }
    
    private func deleteSelected() {
        document.removeElements(with: selectedElementIDs)
        selectedElementIDs.removeAll()
    }
    
    private enum AlignMode { case left, centerX, right, top, centerY, bottom }
    
    private func alignSelected(mode: AlignMode) {
        guard let bounds = document.selectionBounds(for: selectedElementIDs) else { return }
        for id in selectedElementIDs {
            guard var el = document.element(with: id) else { continue }
            let elBounds = el.bounds
            var dx: CGFloat = 0
            var dy: CGFloat = 0
            switch mode {
            case .left: dx = bounds.minX - elBounds.minX
            case .centerX: dx = bounds.midX - elBounds.midX
            case .right: dx = bounds.maxX - elBounds.maxX
            case .top: dy = bounds.minY - elBounds.minY
            case .centerY: dy = bounds.midY - elBounds.midY
            case .bottom: dy = bounds.maxY - elBounds.maxY
            }
            el = el.translated(by: CGPoint(x: dx, y: dy))
            document.updateElement(el)
        }
    }
    
    private func distributeSelected(horizontal: Bool) {
        let items = document.elements.filter { selectedElementIDs.contains($0.id) }
        guard items.count >= 3 else { return }
        if horizontal {
            let sorted = items.sorted { $0.bounds.minX < $1.bounds.minX }
            let totalSpan = (sorted.last?.bounds.maxX ?? 0) - (sorted.first?.bounds.minX ?? 0)
            let totalItemWidth = sorted.reduce(0.0) { $0 + $1.bounds.width }
            let gap = max(0, (totalSpan - totalItemWidth) / CGFloat(sorted.count - 1))
            var curX = sorted.first!.bounds.minX
            for item in sorted {
                let dx = curX - item.bounds.minX
                let updated = item.translated(by: CGPoint(x: dx, y: 0))
                document.updateElement(updated)
                curX += item.bounds.width + gap
            }
        } else {
            let sorted = items.sorted { $0.bounds.minY < $1.bounds.minY }
            let totalSpan = (sorted.last?.bounds.maxY ?? 0) - (sorted.first?.bounds.minY ?? 0)
            let totalItemHeight = sorted.reduce(0.0) { $0 + $1.bounds.height }
            let gap = max(0, (totalSpan - totalItemHeight) / CGFloat(sorted.count - 1))
            var curY = sorted.first!.bounds.minY
            for item in sorted {
                let dy = curY - item.bounds.minY
                let updated = item.translated(by: CGPoint(x: 0, y: dy))
                document.updateElement(updated)
                curY += item.bounds.height + gap
            }
        }
    }
    
    private func changeZOrder(toFront: Bool = false, toBack: Bool = false, step: Int = 0) {
        for id in selectedElementIDs {
            guard var el = document.element(with: id) else { continue }
            if toFront { el.zIndex = 10000 }
            else if toBack { el.zIndex = -10000 }
            else { el.zIndex += step }
            document.updateElement(el)
        }
        document.elements.sort { $0.zIndex < $1.zIndex }
    }
    
    private func buildCommands() -> [CommandItem] {
        var list: [CommandItem] = [
            CommandItem(title: "New Board", subtitle: "Create fresh whiteboard", icon: "plus", shortcut: "⌘N") {
                let newDoc = documentStore.createNewBoard()
                self.document = newDoc
                self.selectedElementIDs = []
            },
            CommandItem(title: "Export PNG", subtitle: "Export board as high-res PNG image", icon: "arrow.down.doc") {
                #if canImport(AppKit)
                if let png = PNGExporter.renderPNG(document: document, scale: 2.0) {
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.png]
                    savePanel.nameFieldStringValue = "\(document.metadata.title).png"
                    if savePanel.runModal() == .OK, let url = savePanel.url {
                        try? png.write(to: url)
                    }
                }
                #endif
            },
            CommandItem(title: "Export PDF", subtitle: "Export vector PDF document", icon: "doc.richtext") {
                #if canImport(AppKit)
                if let pdf = PDFExporter.renderPDF(document: document) {
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.pdf]
                    savePanel.nameFieldStringValue = "\(document.metadata.title).pdf"
                    if savePanel.runModal() == .OK, let url = savePanel.url {
                        try? pdf.write(to: url)
                    }
                }
                #endif
            },
            CommandItem(title: "Export SVG", subtitle: "Export scalable vector SVG", icon: "chevron.left.forwardslash.chevron.right") {
                #if canImport(AppKit)
                let svg = SVGExporter.renderSVG(document: document)
                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [.svg]
                savePanel.nameFieldStringValue = "\(document.metadata.title).svg"
                if savePanel.runModal() == .OK, let url = savePanel.url {
                    try? svg.write(to: url, atomically: true, encoding: .utf8)
                }
                #endif
            },
            CommandItem(title: "Make Visual Guide", subtitle: "Convert notes to Flowchart / Mind Map / Step Cards", icon: "sparkles") {
                self.showVisualGuideDialog = true
            },
            CommandItem(title: "Start Presentation", subtitle: "Present slides in full screen", icon: "play.fill", shortcut: "⌃⌘F") {
                presentationManager.startPresentation(document: document)
            },
            CommandItem(title: "Toggle Camera Finger Tracking", subtitle: "Enable webcam gesture tracking", icon: "video", shortcut: "⌥C") {
                if cameraManager.isTrackingEnabled { cameraManager.stopTracking() } else { cameraManager.startTracking() }
            },
            CommandItem(title: "Board Library", subtitle: "Browse all saved boards", icon: "square.grid.2x2", shortcut: "⌘L") {
                self.showBoardLibrary = true
            },
            CommandItem(title: "Keyboard Shortcuts", subtitle: "View complete shortcut reference", icon: "questionmark.circle", shortcut: "⌘/") {
                self.showCheatSheet = true
            }
        ]
        
        // Add tools to command palette
        for tool in CanvasTool.allCases {
            list.append(CommandItem(title: "Tool: \(tool.rawValue)", icon: tool.iconName, shortcut: tool.shortcutDisplay) {
                self.activeTool = tool
            })
        }
        
        return list
    }
}
