//
//  MediaItem.swift
//  USBPhotoes
//
//  Created by ほりしょー on 2025/08/11.
//

import Foundation
import SwiftUI
import AVFoundation

struct MediaItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let type: MediaType
    let creationDate: Date?
    let fileSize: Int64
    let bookmark: Data?
    
    enum MediaType {
        case image
        case video
        
        var isVideo: Bool {
            return self == .video
        }
    }
    
    var filename: String {
        url.lastPathComponent
    }
    
    var fileExtension: String {
        url.pathExtension.lowercased()
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    func resolveBookmark() throws -> URL {
        guard let bookmark = bookmark else { return url }
        
        var isStale = false
        let resolvedURL = try URL(resolvingBookmarkData: bookmark, 
                                  options: [], 
                                  relativeTo: nil, 
                                  bookmarkDataIsStale: &isStale)
        
        if isStale {
            throw BookmarkError.staleBookmark
        }
        
        return resolvedURL
    }
}

enum BookmarkError: Error {
    case staleBookmark
    case failedToCreateBookmark
}

extension MediaItem {
    static let supportedImageExtensions = ["jpg", "jpeg", "png", "heic", "gif", "bmp", "tiff", "webp"]
    static let supportedVideoExtensions = ["mp4", "mov", "avi", "mkv", "m4v", "3gp", "webm"]
    
    static func isSupported(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedImageExtensions.contains(ext) || supportedVideoExtensions.contains(ext)
    }
    
    static func mediaType(for url: URL) -> MediaType? {
        let ext = url.pathExtension.lowercased()
        if supportedImageExtensions.contains(ext) {
            return .image
        } else if supportedVideoExtensions.contains(ext) {
            return .video
        }
        return nil
    }
}