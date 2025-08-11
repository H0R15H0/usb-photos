# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS application called "USBPhotoes" - a photo gallery app that clones the iPhone Photos app experience. Users can select folders through the iOS document picker and view images and videos with the same intuitive interface as the default iOS Photos app, including grid view, full-screen viewing, zoom gestures, and metadata display.

## Architecture

### Core Components
- **USBPhotoesApp.swift**: Main app entry point using SwiftUI's `@main` attribute
- **ContentView.swift**: Root view that displays the PhotoLibraryView

### Models
- **MediaItem.swift**: Core data model representing photos/videos with metadata and file information

### ViewModels  
- **PhotoLibraryViewModel.swift**: Main business logic for folder selection, media scanning, and state management

### Views
- **PhotoLibraryView.swift**: Main gallery view with grid layout, welcome screen, and loading states
- **PhotoThumbnailView.swift**: Grid item view that generates and displays thumbnails for images/videos
- **FullScreenMediaView.swift**: Full-screen viewer with navigation, gestures, and controls
- **ZoomableImageView.swift**: Zoomable image component with pan and zoom gestures
- **VideoPlayerView.swift**: AVKit-based video player for full-screen video playback
- **MediaInfoView.swift**: Metadata display sheet showing file details, dimensions, and creation info
- **DocumentPicker.swift**: UIDocumentPickerViewController wrapper for SwiftUI folder selection

### Key Features
- Folder selection using UIDocumentPickerViewController for iOS
- Recursive directory scanning for supported media files
- Async thumbnail generation for performance
- iPhone Photos-style grid layout and navigation
- Full-screen viewing with swipe navigation
- Pinch-to-zoom and pan gestures for images
- Video playback with AVPlayer
- Comprehensive metadata display
- Support for common image formats (JPEG, PNG, HEIC, etc.)
- Support for video formats (MP4, MOV, etc.)

## Development Commands

### Building and Running
Since Xcode is the primary development environment for this iOS SwiftUI project:
- Open `USBPhotoes.xcodeproj` in Xcode to build and run
- Use iOS Simulator or connected iPhone/iPad for testing

### Testing
- **Unit Tests**: Located in `USBPhotoesTests/` using Swift Testing framework (`import Testing`)
- **UI Tests**: Located in `USBPhotoesUITests/` using XCTest framework (`import XCTest`) for end-to-end testing
- Run tests through Xcode's Test Navigator or Product → Test menu

### Code Structure
- Main app code in `USBPhotoes/` directory
- Assets and app icons in `USBPhotoes/Assets.xcassets/`
- Standard iOS app bundle structure with Info.plist managed by Xcode

## Notes for Development

- Project uses modern SwiftUI declarative syntax with async/await for image loading
- Uses Swift Testing framework instead of traditional XCTest  
- Implements iPhone Photos app UX patterns: grid layout, full-screen viewer, swipe navigation
- Comprehensive gesture support: tap, double-tap, pinch-to-zoom, pan, and swipe
- Async thumbnail generation for smooth scrolling performance
- Uses UIKit (UIDocumentPickerViewController) for iOS-native folder selection
- AVKit integration for video playback with native controls
- No external dependencies - uses only Apple's native frameworks