//
//  RulersView.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import SwiftUI
import CoreGraphics

public struct RulersView: View {
    public var offset: CGPoint
    public var zoom: CGFloat
    public var isDarkMode: Bool
    
    public init(offset: CGPoint, zoom: CGFloat, isDarkMode: Bool = false) {
        self.offset = offset
        self.zoom = zoom
        self.isDarkMode = isDarkMode
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Top Horizontal Ruler
                Canvas { context, size in
                    let step: CGFloat = 100 * zoom
                    let startX = offset.x.truncatingRemainder(dividingBy: step)
                    
                    var x = startX
                    while x < size.width {
                        let canvasX = (x / zoom) - offset.x
                        context.stroke(
                            Path { p in
                                p.move(to: CGPoint(x: x, y: 12))
                                p.addLine(to: CGPoint(x: x, y: 20))
                            },
                            with: .color(isDarkMode ? .gray.opacity(0.4) : .gray.opacity(0.6)),
                            lineWidth: 1
                        )
                        context.draw(
                            Text("\(Int(canvasX))").font(.system(size: 9, design: .monospaced)).foregroundColor(.secondary),
                            at: CGPoint(x: x + 14, y: 6)
                        )
                        x += step
                    }
                }
                .frame(height: 20)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.primary.opacity(0.1)), alignment: .bottom)
                
                // Left Vertical Ruler
                Canvas { context, size in
                    let step: CGFloat = 100 * zoom
                    let startY = offset.y.truncatingRemainder(dividingBy: step)
                    
                    var y = startY
                    while y < size.height {
                        let canvasY = (y / zoom) - offset.y
                        context.stroke(
                            Path { p in
                                p.move(to: CGPoint(x: 12, y: y))
                                p.addLine(to: CGPoint(x: 20, y: y))
                            },
                            with: .color(isDarkMode ? .gray.opacity(0.4) : .gray.opacity(0.6)),
                            lineWidth: 1
                        )
                        context.draw(
                            Text("\(Int(canvasY))").font(.system(size: 9, design: .monospaced)).foregroundColor(.secondary),
                            at: CGPoint(x: 6, y: y + 10)
                        )
                        y += step
                    }
                }
                .frame(width: 20)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
                .overlay(Rectangle().frame(width: 1).foregroundColor(Color.primary.opacity(0.1)), alignment: .trailing)
                
                // Corner Square
                Rectangle()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color(nsColor: .windowBackgroundColor))
            }
        }
    }
}
