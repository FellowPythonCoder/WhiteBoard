//
//  SlatePackage.swift
//  Slate
//
//  Created for Slate Native Whiteboard.
//

import Foundation

/// Handles reading and writing of `.slate` document packages.
public struct SlatePackage: Sendable {
    public static let packageExtension = "slate"
    public static let documentFilename = "document.json"
    public static let metadataFilename = "metadata.json"
    public static let assetsDirectoryName = "assets"
    public static let thumbnailFilename = "thumbnail.png"
    
    public static func encode(document: SlateDocument, thumbnailPNG: Data? = nil, assetDataMap: [String: Data] = [:]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let docData = try encoder.encode(document)
        let metaData = try encoder.encode(document.metadata)
        
        var fileWrappers: [String: FileWrapper] = [:]
        fileWrappers[documentFilename] = FileWrapper(regularFileWithContents: docData)
        fileWrappers[metadataFilename] = FileWrapper(regularFileWithContents: metaData)
        
        if let thumb = thumbnailPNG {
            fileWrappers[thumbnailFilename] = FileWrapper(regularFileWithContents: thumb)
        }
        
        if !assetDataMap.isEmpty {
            var assetWrappers: [String: FileWrapper] = [:]
            for (filename, data) in assetDataMap {
                assetWrappers[filename] = FileWrapper(regularFileWithContents: data)
            }
            let assetsDirWrapper = FileWrapper(directoryWithFileWrappers: assetWrappers)
            fileWrappers[assetsDirectoryName] = assetsDirWrapper
        }
        
        let packageWrapper = FileWrapper(directoryWithFileWrappers: fileWrappers)
        guard let serializedData = packageWrapper.serializedRepresentation else {
            throw NSError(domain: "SlatePackage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize package wrapper"])
        }
        return serializedData
    }
    
    public static func save(document: SlateDocument, to url: URL, thumbnailPNG: Data? = nil, assetDataMap: [String: Data] = [:]) throws {
        let fm = FileManager.default
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let docData = try encoder.encode(document)
        let metaData = try encoder.encode(document.metadata)
        
        try docData.write(to: url.appendingPathComponent(documentFilename), options: .atomic)
        try metaData.write(to: url.appendingPathComponent(metadataFilename), options: .atomic)
        
        if let thumb = thumbnailPNG {
            try thumb.write(to: url.appendingPathComponent(thumbnailFilename), options: .atomic)
        }
        
        if !assetDataMap.isEmpty {
            let assetsUrl = url.appendingPathComponent(assetsDirectoryName)
            if !fm.fileExists(atPath: assetsUrl.path) {
                try fm.createDirectory(at: assetsUrl, withIntermediateDirectories: true)
            }
            for (filename, data) in assetDataMap {
                try data.write(to: assetsUrl.appendingPathComponent(filename), options: .atomic)
            }
        }
    }
    
    public static func load(from url: URL) throws -> (document: SlateDocument, assets: [String: Data], thumbnail: Data?) {
        let fm = FileManager.default
        let docUrl = url.appendingPathComponent(documentFilename)
        
        guard fm.fileExists(atPath: docUrl.path) else {
            throw NSError(domain: "SlatePackage", code: 2, userInfo: [NSLocalizedDescriptionKey: "document.json not found in package"])
        }
        
        let docData = try Data(contentsOf: docUrl)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let doc = try decoder.decode(SlateDocument.self, from: docData)
        
        var assets: [String: Data] = [:]
        let assetsUrl = url.appendingPathComponent(assetsDirectoryName)
        if fm.fileExists(atPath: assetsUrl.path), let items = try? fm.contentsOfDirectory(atPath: assetsUrl.path) {
            for item in items {
                let fileUrl = assetsUrl.appendingPathComponent(item)
                if let data = try? Data(contentsOf: fileUrl) {
                    assets[item] = data
                }
            }
        }
        
        var thumbData: Data? = nil
        let thumbUrl = url.appendingPathComponent(thumbnailFilename)
        if fm.fileExists(atPath: thumbUrl.path) {
            thumbData = try? Data(contentsOf: thumbUrl)
        }
        
        return (doc, assets, thumbData)
    }
    
    public static func readMetadata(from url: URL) -> BoardMetadata? {
        let metaUrl = url.appendingPathComponent(metadataFilename)
        guard let data = try? Data(contentsOf: metaUrl) else {
            // Fallback to reading document.json
            let docUrl = url.appendingPathComponent(documentFilename)
            guard let docData = try? Data(contentsOf: docUrl) else { return nil }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try? decoder.decode(SlateDocument.self, from: docData))?.metadata
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BoardMetadata.self, from: data)
    }
}
