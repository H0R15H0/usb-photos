//
//  PhotoLibraryViewModel.swift
//  USBPhotoes
//
//  Created by ほりしょー on 2025/08/11.
//

import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
class PhotoLibraryViewModel: ObservableObject {
    @Published var mediaItems: [MediaItem] = []
    @Published var selectedFolderURL: URL?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fileManager = FileManager.default
    
    func selectFolder() {
        // For iOS, we'll use the Photos library or Documents picker
        // This will be handled by the view using UIDocumentPickerViewController
    }
    
    func loadMediaItems(from folderURL: URL) {
        selectedFolderURL = folderURL
        scanAndLoadMediaItems(from: folderURL)
    }
    
    private func scanAndLoadMediaItems(from folderURL: URL) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let items = try await scanDirectory(folderURL)
                await MainActor.run {
                    self.mediaItems = items.sorted { item1, item2 in
                        (item1.creationDate ?? Date.distantPast) > (item2.creationDate ?? Date.distantPast)
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load media: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func scanDirectory(_ url: URL) async throws -> [MediaItem] {
        guard url.startAccessingSecurityScopedResource() else {
            throw PhotoLibraryError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        var items: [MediaItem] = []
        let resourceKeys: [URLResourceKey] = [.creationDateKey, .fileSizeKey, .isDirectoryKey]
        
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: resourceKeys) {
            for case let fileURL as URL in enumerator {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                
                guard let isDirectory = resourceValues.isDirectory, !isDirectory else { continue }
                guard MediaItem.isSupported(url: fileURL) else { continue }
                guard let mediaType = MediaItem.mediaType(for: fileURL) else { continue }
                
                let item = MediaItem(
                    url: fileURL,
                    type: mediaType,
                    creationDate: resourceValues.creationDate,
                    fileSize: Int64(resourceValues.fileSize ?? 0)
                )
                items.append(item)
            }
        }
        
        return items
    }
}

enum PhotoLibraryError: LocalizedError {
    case accessDenied
    case invalidDirectory
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to the selected folder was denied"
        case .invalidDirectory:
            return "The selected path is not a valid directory"
        }
    }
}