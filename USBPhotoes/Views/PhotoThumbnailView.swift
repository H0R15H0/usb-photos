//
//  PhotoThumbnailView.swift
//  USBPhotoes
//
//  Created by ほりしょー on 2025/08/11.
//

import SwiftUI
import AVKit

struct PhotoThumbnailView: View {
    let mediaItem: MediaItem
    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let thumbnailImage = thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .font(.title)
                    .foregroundColor(.gray)
            }
            
            if mediaItem.type.isVideo {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 70, height: 70)
        .clipped()
        .task {
            await loadThumbnail()
        }
    }
    
    @MainActor
    private func loadThumbnail() async {
        isLoading = true
        
        do {
            // Try to resolve the file URL using bookmark if available
            let fileURL = try mediaItem.resolveBookmark()
            
            // Start accessing security scoped resource
            let hasAccess = fileURL.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }
            
            let image = try await generateThumbnail(for: mediaItem, resolvedURL: fileURL)
            thumbnailImage = image
        } catch {
            print("Failed to load thumbnail for \(mediaItem.filename): \(error)")
        }
        
        isLoading = false
    }
    
    private func generateThumbnail(for mediaItem: MediaItem, resolvedURL: URL) async throws -> UIImage {
        let size = CGSize(width: 300, height: 300)
        
        switch mediaItem.type {
        case .image:
            return try await generateImageThumbnail(url: resolvedURL, size: size)
        case .video:
            return try await generateVideoThumbnail(url: resolvedURL, size: size)
        }
    }
    
    private func generateImageThumbnail(url: URL, size: CGSize) async throws -> UIImage {
        // Security-scoped access is already handled at the top level
        
        // Try CGImageSource first (more efficient for thumbnails)
        if let image = try? createThumbnailWithImageSource(url: url, size: size) {
            return image
        }
        
        // Fallback: Try direct UIImage loading with Data
        return try await loadImageDirectly(url: url, size: size)
    }
    
    private func createThumbnailWithImageSource(url: URL, size: CGSize) throws -> UIImage {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ThumbnailError.failedToCreateImageSource
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]
        
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            throw ThumbnailError.failedToCreateThumbnail
        }
        
        return UIImage(cgImage: thumbnail)
    }
    
    private func loadImageDirectly(url: URL, size: CGSize) async throws -> UIImage {
        // Security-scoped access is already handled at the top level
        let data = try Data(contentsOf: url)
        guard let originalImage = UIImage(data: data) else {
            throw ThumbnailError.failedToCreateThumbnail
        }
        
        // Resize the image to thumbnail size
        let renderer = UIGraphicsImageRenderer(size: size)
        let resizedImage = renderer.image { _ in
            originalImage.draw(in: CGRect(origin: .zero, size: size))
        }
        
        return resizedImage
    }
    
    private func generateVideoThumbnail(url: URL, size: CGSize) async throws -> UIImage {
        // Security-scoped access is already handled at the top level
        return try await createVideoThumbnail(url: url, size: size)
    }
    
    private func createVideoThumbnail(url: URL, size: CGSize) async throws -> UIImage {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = size
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let cgImage = cgImage else {
                    continuation.resume(throwing: ThumbnailError.failedToCreateThumbnail)
                    return
                }
                
                let uiImage = UIImage(cgImage: cgImage)
                continuation.resume(returning: uiImage)
            }
        }
    }
}

enum ThumbnailError: LocalizedError {
    case failedToCreateImageSource
    case failedToCreateThumbnail
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateImageSource:
            return "画像ソースの作成に失敗しました"
        case .failedToCreateThumbnail:
            return "サムネイルの作成に失敗しました"
        }
    }
}