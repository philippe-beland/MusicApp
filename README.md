# MusicApp

A modern iOS music application built with SwiftUI and MusicKit, designed to provide an Apple Music-like experience with enhanced features for music discovery and playback control.

## 🎵 Features

### Core Functionality
- **Apple Music Integration**: Seamless access to Apple Music catalog
- **Album Discovery**: Browse albums by artist with automatic sorting by release date
- **Track Playback**: Full music playback with queue management
- **Artist Details**: Comprehensive artist pages with album collections
- **Track Comments**: Add personal notes and comments to individual tracks

### User Interface
- **Modern Design**: Clean, Apple Music-inspired interface
- **Floating Player Controls**: Always-accessible playback controls
- **Responsive Layout**: Optimized for all iOS devices
- **French Localization**: Complete French language support

### Advanced Features
- **Smart Queue Management**: Play from any track and continue through the album
- **Album Sampling**: Sample entire albums with 30-second previews
- **Lazy Loading**: Efficient data loading for better performance
- **Error Handling**: Graceful handling of network and playback errors

## 📱 Screenshots

### Main Views
- **Home View**: Discover albums in horizontal scrolling carousels
- **Album Detail View**: Complete album information with track listings
- **Artist Detail View**: Artist profiles with album collections
- **Track Detail View**: Individual track information with comment system

## 🛠 Technical Stack

- **SwiftUI**: Modern declarative UI framework
- **MusicKit**: Apple's music framework for catalog access
- **Async/Await**: Modern concurrency for network operations

## 📋 Requirements

- iOS 18.5+
- Xcode 16.0+
- Apple Developer Account
- Apple Music subscription (for full functionality)

## 🚀 Installation

### Prerequisites
1. Install Xcode from the App Store
2. Ensure you have an Apple Developer Account
3. Have an Apple Music subscription

### Setup Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/MusicApp.git
   cd MusicApp
   ```

2. Open the project in Xcode:
   ```bash
   open MusicApp.xcodeproj
   ```

3. Configure your project:
   - Select your team in Signing & Capabilities
   - Add "Apple Music" capability
   - Update bundle identifier if needed

4. Build and run on a physical device (MusicKit requires a real device)

## 🔧 Configuration

### Apple Music Capability
The app requires the Apple Music capability to access the music catalog:

1. In Xcode, select your project
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "Apple Music"

### Info.plist Permissions
Ensure your `Info.plist` includes:
```xml
<key>NSAppleMusicUsageDescription</key>
<string>This app needs access to your music library to provide playback and discovery features.</string>
```

## 🎮 Usage Guide

### Getting Started
1. **Launch the App**: Open MusicApp on your device
2. **Grant Permissions**: Allow access to Apple Music when prompted
3. **Browse Content**: Use the tab bar to navigate between Home, Library, and Search

### Navigation
- **Home Tab**: Discover albums and recent content
- **Library Tab**: Access your personal music library
- **Search Tab**: Find specific artists, albums, or tracks

### Music Playback
- **Tap Album**: Navigate to album details
- **Tap Track Row**: Start playback from that track through the end of the album
- **Tap "..."**: Open track details and add comments
- **Floating Controls**: Use the bottom player controls for playback management

### Album Features
- **View Details**: See complete album information
- **Track List**: Browse all tracks with durations
- **Play Controls**: Start playback from any track
- **Comments**: Add personal notes to tracks

## 🏗 Architecture

### Project Structure
```
MusicApp/
├── MusicApp/
│   ├── Views/
│   │   ├── HomeView.swift
│   │   ├── LibraryView.swift
│   │   ├── SearchView.swift
│   │   ├── MusicPlayerControls.swift
│   │   └── DetailsViews/
│   │       ├── AlbumDetailView.swift
│   │       ├── ArtistDetailView.swift
│   │       └── TrackDetailView.swift
│   ├── Models/
│   │   └── Album.swift
│   ├── ContentView.swift
│   └── MusicAppApp.swift
```

### Key Components
- **HomeView**: Main discovery interface with album carousels
- **AlbumDetailView**: Complete album information and track management
- **MusicPlayerControls**: Floating playback controls
- **TrackDetailView**: Individual track information and comments

## 🔄 State Management

The app uses a combination of:
- **@State**: Local view state
- **@ObservedObject**: MusicKit player state observation
- **Async/Await**: Network operations and data fetching

## 🎯 Future Enhancements

- [ ] Search functionality implementation
- [ ] Library view with personal music
- [ ] Playlist creation and management
- [ ] Advanced AI music analysis

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

There is no licence yet on this project.

## 🙏 Acknowledgments

- Apple for MusicKit framework
- SwiftUI community for inspiration
- Apple Music for the music catalog

## 📞 Support

For support, email phil_beland@hotmail.com or create an issue in this repository.

---

**Note**: This app requires a physical iOS device to run properly due to MusicKit limitations in the simulator. 