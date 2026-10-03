//
//  SnapshotHistoryView.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public struct SnapshotHistoryView: View {
    @Binding public var document: SlateDocument
    public var onClose: () -> Void
    public var onRestore: (BoardSnapshot) -> Void
    
    @State private var snapshotLabel: String = ""
    
    public init(document: Binding<SlateDocument>, onClose: @escaping () -> Void, onRestore: @escaping (BoardSnapshot) -> Void) {
        self._document = document
        self.onClose = onClose
        self.onRestore = onRestore
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Version History")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Create Checkpoint Bar
            HStack(spacing: 8) {
                TextField("Snapshot label...", text: $snapshotLabel)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                
                Button("Save Checkpoint") {
                    let label = snapshotLabel.isEmpty ? "Manual Checkpoint" : snapshotLabel
                    document.createSnapshot(label: label)
                    snapshotLabel = ""
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Snapshots List
            ScrollView {
                if document.snapshots.isEmpty {
                    Text("No snapshots saved yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(24)
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(document.snapshots) { snap in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(snap.label)
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("\(snap.timestamp, style: .date) \(snap.timestamp, style: .time) • \(snap.elementCount) items")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Restore") {
                                    onRestore(snap)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                            .padding(8)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(8)
                }
            }
        }
        .frame(width: 320, height: 380)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}
