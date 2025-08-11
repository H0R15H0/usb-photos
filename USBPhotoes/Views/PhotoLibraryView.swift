//
//  PhotoLibraryView.swift
//  USBPhotoes
//
//  Created by ほりしょー on 2025/08/11.
//

import SwiftUI

struct PhotoLibraryView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    @State private var selectedItem: MediaItem?
    @State private var showingDocumentPicker = false
    
    let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.selectedFolderURL == nil {
                    welcomeView
                } else if viewModel.isLoading {
                    loadingView
                } else if viewModel.mediaItems.isEmpty {
                    emptyStateView
                } else {
                    photoGridView
                }
            }
            .navigationTitle("写真")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("フォルダを選択") {
                        showingDocumentPicker = true
                    }
                }
            }
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .fullScreenCover(item: $selectedItem) { item in
            FullScreenMediaView(
                mediaItem: item,
                mediaItems: viewModel.mediaItems,
                isPresented: Binding<Bool>(
                    get: { selectedItem != nil },
                    set: { if !$0 { selectedItem = nil } }
                )
            )
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(selectedURL: .constant(nil)) { url in
                viewModel.loadMediaItems(from: url)
                showingDocumentPicker = false
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("写真アプリへようこそ")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("写真やビデオを表示するフォルダを選択してください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("フォルダを選択") {
                showingDocumentPicker = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("写真を読み込み中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("写真が見つかりません")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("このフォルダには、サポートされている画像またはビデオファイルが含まれていません。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.mediaItems) { item in
                    PhotoThumbnailView(mediaItem: item)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .onTapGesture {
                            selectedItem = item
                        }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}
