//
//  CommandPalette.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI

public struct CommandItem: Identifiable, Sendable {
    public var id = UUID()
    public var title: String
    public var subtitle: String?
    public var icon: String
    public var shortcut: String?
    public var action: @MainActor () -> Void
}

public struct CommandPalette: View {
    @Binding public var isPresented: Bool
    public var commands: [CommandItem]
    
    @State private var searchText: String = ""
    @State private var selectedIndex: Int = 0
    
    public init(isPresented: Binding<Bool>, commands: [CommandItem]) {
        self._isPresented = isPresented
        self.commands = commands
    }
    
    private var filteredCommands: [CommandItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return commands }
        return commands.filter {
            $0.title.lowercased().contains(q) || ($0.subtitle?.lowercased().contains(q) ?? false)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Header
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Type a command or search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Results List
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { idx, item in
                        HStack(spacing: 10) {
                            Image(systemName: item.icon)
                                .font(.system(size: 13))
                                .frame(width: 20)
                                .foregroundColor(idx == selectedIndex ? .accentColor : .secondary)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title)
                                    .font(.system(size: 13, weight: .medium))
                                if let sub = item.subtitle {
                                    Text(sub)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if let sc = item.shortcut {
                                Text(sc)
                                    .font(.system(size: 11, design: .monospaced))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.primary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(idx == selectedIndex ? Color.accentColor.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isPresented = false
                            item.action()
                        }
                    }
                }
                .padding(6)
            }
            .frame(maxHeight: 280)
        }
        .frame(width: 440)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
}
