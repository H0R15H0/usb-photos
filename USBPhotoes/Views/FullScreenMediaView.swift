//
//  FullScreenMediaView.swift
//  USBPhotoes
//
//  Created by ほりしょー on 2025/08/11.
//

import SwiftUI
import AVKit

struct FullScreenMediaView: View {
    let mediaItem: MediaItem
    let mediaItems: [MediaItem]
    @Binding var isPresented: Bool
    
    @State private var currentIndex: Int
    @State private var showControls = true
    @State private var showInfo = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private var currentItem: MediaItem {
        guard currentIndex < mediaItems.count else { return mediaItem }
        return mediaItems[currentIndex]
    }
    
    init(mediaItem: MediaItem, mediaItems: [MediaItem], isPresented: Binding<Bool>) {
        self.mediaItem = mediaItem
        self.mediaItems = mediaItems
        self._isPresented = isPresented
        
        if let index = mediaItems.firstIndex(of: mediaItem) {
            self._currentIndex = State(initialValue: index)
        } else {
            self._currentIndex = State(initialValue: 0)
        }
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            
            GeometryReader { geometry in
                ZStack {
                    if currentItem.type.isVideo {
                        VideoPlayerView(url: currentItem.url)
                            .onTapGesture {
                                toggleControls()
                            }
                    } else {
                        ZoomableImageView(
                            url: currentItem.url,
                            zoomScale: $zoomScale,
                            offset: $offset,
                            lastOffset: $lastOffset
                        )
                        .onTapGesture {
                            toggleControls()
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if zoomScale <= 1.0 {
                                        let translation = value.translation
                                        if abs(translation.width) > abs(translation.height) && abs(translation.width) > 50 {
                                            // Horizontal swipe for navigation
                                        } else {
                                            // Vertical swipe to dismiss
                                            offset = CGSize(
                                                width: lastOffset.width,
                                                height: lastOffset.height + translation.height
                                            )
                                        }
                                    }
                                }
                                .onEnded { value in
                                    if zoomScale <= 1.0 {
                                        let translation = value.translation
                                        let velocity = value.velocity
                                        
                                        if abs(translation.width) > abs(translation.height) && abs(translation.width) > 100 {
                                            // Navigation swipe
                                            if translation.width > 0 {
                                                navigateToPrevious()
                                            } else {
                                                navigateToNext()
                                            }
                                        } else if abs(translation.height) > 100 || abs(velocity.height) > 500 {
                                            // Dismiss swipe
                                            isPresented = false
                                        } else {
                                            // Reset position
                                            withAnimation(.spring()) {
                                                offset = lastOffset
                                            }
                                        }
                                    }
                                }
                        )
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            
            if showControls {
                VStack {
                    // Top controls
                    HStack {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                        }
                        
                        Spacer()
                        
                        Button(action: { showInfo.toggle() }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.6), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack {
                        Button(action: navigateToPrevious) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(canNavigatePrevious ? .white : .gray)
                                .padding()
                        }
                        .disabled(!canNavigatePrevious)
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) of \(mediaItems.count)")
                            .foregroundColor(.white)
                            .font(.caption)
                        
                        Spacer()
                        
                        Button(action: navigateToNext) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(canNavigateNext ? .white : .gray)
                                .padding()
                        }
                        .disabled(!canNavigateNext)
                    }
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
        .onAppear {
            hideControlsAfterDelay()
        }
        .sheet(isPresented: $showInfo) {
            MediaInfoView(mediaItem: currentItem)
        }
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    if !currentItem.type.isVideo {
                        toggleZoom()
                    }
                }
        )
    }
    
    private var canNavigatePrevious: Bool {
        currentIndex > 0
    }
    
    private var canNavigateNext: Bool {
        currentIndex < mediaItems.count - 1
    }
    
    private func navigateToPrevious() {
        guard canNavigatePrevious else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex -= 1
            resetZoom()
        }
        showControlsTemporarily()
    }
    
    private func navigateToNext() {
        guard canNavigateNext else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex += 1
            resetZoom()
        }
        showControlsTemporarily()
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        if showControls {
            hideControlsAfterDelay()
        }
    }
    
    private func showControlsTemporarily() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls = true
        }
        hideControlsAfterDelay()
    }
    
    private func hideControlsAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func toggleZoom() {
        withAnimation(.spring()) {
            if zoomScale > 1.0 {
                resetZoom()
            } else {
                zoomScale = 2.0
            }
        }
    }
    
    private func resetZoom() {
        withAnimation(.spring()) {
            zoomScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
}
