//
//  BlobDetector.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation
import CoreGraphics

public final class BlobDetector {
    
    public static func detectBlobs(
        maskBuffer: UnsafePointer<UInt8>,
        width: Int,
        height: Int,
        minPixelArea: Int = 18,
        maxPixelArea: Int = 12000
    ) -> [CameraTrackedBlob] {
        var labels = [Int](repeating: 0, count: width * height)
        var currentLabel = 0
        var parent = [Int]() // Disjoint-set union for equivalence
        parent.append(0) // 0 is background
        
        func findRoot(_ i: Int) -> Int {
            var root = i
            while root != parent[root] {
                root = parent[root]
            }
            return root
        }
        
        func unionSets(_ i: Int, _ j: Int) {
            let rootI = findRoot(i)
            let rootJ = findRoot(j)
            if rootI != rootJ {
                parent[max(rootI, rootJ)] = min(rootI, rootJ)
            }
        }
        
        // Pass 1: Labeling with 4-connectivity
        for y in 0..<height {
            let rowOffset = y * width
            for x in 0..<width {
                let idx = rowOffset + x
                if maskBuffer[idx] == 0 { continue }
                
                let northLabel = y > 0 ? labels[(y - 1) * width + x] : 0
                let westLabel = x > 0 ? labels[y * width + (x - 1)] : 0
                
                if northLabel == 0 && westLabel == 0 {
                    currentLabel += 1
                    parent.append(currentLabel)
                    labels[idx] = currentLabel
                } else if northLabel > 0 && westLabel == 0 {
                    labels[idx] = northLabel
                } else if northLabel == 0 && westLabel > 0 {
                    labels[idx] = westLabel
                } else {
                    let minL = min(northLabel, westLabel)
                    labels[idx] = minL
                    unionSets(northLabel, westLabel)
                }
            }
        }
        
        if currentLabel == 0 { return [] }
        
        // Pass 2: Aggregate moments, bounding box, and area
        struct BlobAccumulator {
            var sumX: Int = 0
            var sumY: Int = 0
            var area: Int = 0
            var minX: Int = Int.max
            var maxX: Int = Int.min
            var minY: Int = Int.max
            var maxY: Int = Int.min
        }
        
        var accumulators: [Int: BlobAccumulator] = [:]
        
        for y in 0..<height {
            let rowOffset = y * width
            for x in 0..<width {
                let lbl = labels[rowOffset + x]
                if lbl == 0 { continue }
                let root = findRoot(lbl)
                
                var acc = accumulators[root] ?? BlobAccumulator()
                acc.sumX += x
                acc.sumY += y
                acc.area += 1
                if x < acc.minX { acc.minX = x }
                if x > acc.maxX { acc.maxX = x }
                if y < acc.minY { acc.minY = y }
                if y > acc.maxY { acc.maxY = y }
                accumulators[root] = acc
            }
        }
        
        // Convert to CameraTrackedBlob array
        var results: [CameraTrackedBlob] = []
        for (_, acc) in accumulators {
            if acc.area >= minPixelArea && acc.area <= maxPixelArea {
                let cx = CGFloat(acc.sumX) / CGFloat(acc.area) / CGFloat(width)
                let cy = CGFloat(acc.sumY) / CGFloat(acc.area) / CGFloat(height)
                let bx = CGFloat(acc.minX) / CGFloat(width)
                let by = CGFloat(acc.minY) / CGFloat(height)
                let bw = CGFloat(acc.maxX - acc.minX + 1) / CGFloat(width)
                let bh = CGFloat(acc.maxY - acc.minY + 1) / CGFloat(height)
                
                results.append(CameraTrackedBlob(
                    centroid: CGPoint(x: cx, y: cy),
                    pixelArea: acc.area,
                    boundingBox: CGRect(x: bx, y: by, width: bw, height: bh)
                ))
            }
        }
        
        // Sort descending by area
        results.sort { $0.pixelArea > $1.pixelArea }
        return results
    }
}
