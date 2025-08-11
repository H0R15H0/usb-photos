//
//  VideoPlayerView.swift
//  USBPhotoes
//
//  Created by ほりしょー on 2025/08/11.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var showControls = true
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player) {
                    // Custom overlay controls could go here
                }
                .onAppear {
                    player.play()
                }
                .onDisappear {
                    player.pause()
                }
            } else {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading video...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Observer for when video ends
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            // Optionally restart video or show replay button
            player?.seek(to: CMTime.zero)
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
}