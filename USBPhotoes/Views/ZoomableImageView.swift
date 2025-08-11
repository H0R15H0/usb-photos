//
//  ZoomableImageView.swift
//  USBPhotoes
//
//  Created by ほりしょー on 2025/08/11.
//

import SwiftUI

struct ZoomableImageView: View {
    let url: URL
    @Binding var zoomScale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastOffset: CGSize
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(zoomScale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / zoomScale
                                        zoomScale *= delta
                                        zoomScale = max(1.0, min(zoomScale, 5.0))
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        if zoomScale > 1.0 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { value in
                                        lastOffset = offset
                                        
                                        // Constrain the offset to keep image within bounds
                                        let maxOffsetX = max(0, (image.size.width * zoomScale - geometry.size.width) / 2)
                                        let maxOffsetY = max(0, (image.size.height * zoomScale - geometry.size.height) / 2)
                                        
                                        let constrainedOffset = CGSize(
                                            width: max(-maxOffsetX, min(maxOffsetX, offset.width)),
                                            height: max(-maxOffsetY, min(maxOffsetY, offset.height))
                                        )
                                        
                                        if constrainedOffset != offset {
                                            withAnimation(.spring()) {
                                                offset = constrainedOffset
                                                lastOffset = constrainedOffset
                                            }
                                        }
                                    }
                            )
                        )
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("画像を読み込めません")
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .task {
            await loadImage()
        }
        .onChange(of: url) { newURL in
            Task {
                await loadImage()
            }
        }
    }
    
    @MainActor
    private func loadImage() async {
        isLoading = true
        
        do {
            let data = try Data(contentsOf: url)
            guard let uiImage = UIImage(data: data) else {
                throw ImageLoadError.failedToLoad
            }
            image = uiImage
        } catch {
            print("Failed to load image: \(error)")
            image = nil
        }
        
        isLoading = false
    }
}

enum ImageLoadError: LocalizedError {
    case failedToLoad
    
    var errorDescription: String? {
        switch self {
        case .failedToLoad:
            return "画像の読み込みに失敗しました"
        }
    }
}
