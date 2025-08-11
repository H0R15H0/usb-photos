//
//  MediaInfoView.swift
//  USBPhotoes
//
//  Created by ほりしょー on 2025/08/11.
//

import SwiftUI
import AVFoundation
import CoreLocation

struct MediaInfoView: View {
    let mediaItem: MediaItem
    @State private var metadata: MediaMetadata?
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("一般") {
                    InfoRow(label: "名前", value: mediaItem.filename)
                    InfoRow(label: "種類", value: mediaItem.type.isVideo ? "ビデオ" : "画像")
                    InfoRow(label: "サイズ", value: formatFileSize(mediaItem.fileSize))
                    
                    if let creationDate = mediaItem.creationDate {
                        InfoRow(label: "作成日", value: formatDate(creationDate))
                    }
                }
                
                if let metadata = metadata {
                    Section("詳細") {
                        if let dimensions = metadata.dimensions {
                            InfoRow(label: "解像度", value: "\(Int(dimensions.width)) × \(Int(dimensions.height))")
                        }
                        
                        if let duration = metadata.duration {
                            InfoRow(label: "再生時間", value: formatDuration(duration))
                        }
                        
                        if let colorSpace = metadata.colorSpace {
                            InfoRow(label: "色空間", value: colorSpace)
                        }
                        
                        if let bitRate = metadata.bitRate {
                            InfoRow(label: "ビットレート", value: formatBitRate(bitRate))
                        }
                        
                        if let frameRate = metadata.frameRate {
                            InfoRow(label: "フレームレート", value: "\(String(format: "%.1f", frameRate)) fps")
                        }
                    }
                    
                    if let location = metadata.location {
                        Section("位置情報") {
                            InfoRow(label: "座標", value: formatCoordinates(location))
                        }
                    }
                } else if isLoading {
                    Section("詳細") {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("メタデータを読み込み中...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("パス") {
                    InfoRow(label: "場所", value: mediaItem.url.path)
                        .font(.caption)
                }
            }
            .navigationTitle("情報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadMetadata()
        }
    }
    
    @MainActor
    private func loadMetadata() async {
        isLoading = true
        
        do {
            metadata = try await extractMetadata(from: mediaItem)
        } catch {
            print("Failed to extract metadata: \(error)")
        }
        
        isLoading = false
    }
    
    private func extractMetadata(from mediaItem: MediaItem) async throws -> MediaMetadata {
        switch mediaItem.type {
        case .image:
            return try await extractImageMetadata(from: mediaItem.url)
        case .video:
            return try await extractVideoMetadata(from: mediaItem.url)
        }
    }
    
    private func extractImageMetadata(from url: URL) async throws -> MediaMetadata {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw MetadataError.failedToCreateSource
        }
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            throw MetadataError.failedToExtractProperties
        }
        
        var metadata = MediaMetadata()
        
        // Dimensions
        if let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
           let height = properties[kCGImagePropertyPixelHeight as String] as? Int {
            metadata.dimensions = CGSize(width: width, height: height)
        }
        
        // Color space
        if let colorModel = properties[kCGImagePropertyColorModel as String] as? String {
            metadata.colorSpace = colorModel
        }
        
        return metadata
    }
    
    private func extractVideoMetadata(from url: URL) async throws -> MediaMetadata {
        let asset = AVAsset(url: url)
        
        var metadata = MediaMetadata()
        
        // Duration
        let duration = try await asset.load(.duration)
        if duration.isValid && !duration.isIndefinite {
            metadata.duration = CMTimeGetSeconds(duration)
        }
        
        // Video tracks
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        if let videoTrack = videoTracks.first {
            let naturalSize = try await videoTrack.load(.naturalSize)
            metadata.dimensions = naturalSize
            
            let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
            if nominalFrameRate > 0 {
                metadata.frameRate = nominalFrameRate
            }
            
            let estimatedDataRate = try await videoTrack.load(.estimatedDataRate)
            if estimatedDataRate > 0 {
                metadata.bitRate = Int64(estimatedDataRate)
            }
        }
        
        return metadata
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct MediaMetadata {
    var dimensions: CGSize?
    var duration: Double?
    var colorSpace: String?
    var bitRate: Int64?
    var frameRate: Float?
    var location: CLLocationCoordinate2D?
}

enum MetadataError: LocalizedError {
    case failedToCreateSource
    case failedToExtractProperties
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateSource:
            return "画像ソースの作成に失敗しました"
        case .failedToExtractProperties:
            return "画像プロパティの抽出に失敗しました"
        }
    }
}

// Helper formatting functions
private func formatFileSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useAll]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

private func formatDuration(_ seconds: Double) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    return String(format: "%d:%02d", minutes, remainingSeconds)
}

private func formatBitRate(_ bitRate: Int64) -> String {
    let mbps = Double(bitRate) / 1_000_000
    return String(format: "%.1f Mbps", mbps)
}

private func formatCoordinates(_ location: CLLocationCoordinate2D) -> String {
    return String(format: "%.6f, %.6f", location.latitude, location.longitude)
}