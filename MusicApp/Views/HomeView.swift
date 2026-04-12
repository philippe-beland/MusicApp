import SwiftUI

// MARK: - Carousel

struct WorkCarousel: View {
    let title: String
    let works: [Work]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(works) { work in
                        NavigationLink(destination: WorkDetailView(work: work)) {
                            WorkCard(work: work, size: 150)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Work Card

struct WorkCard: View {
    let work: Work
    let size: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WorkArtworkPlaceholder(work: work, height: size)
                .frame(width: size)

            Text(work.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
            Text(work.artist.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: size)
    }
}

// MARK: - Shared Artwork Placeholder

struct WorkArtworkPlaceholder: View {
    let work: Work
    let height: CGFloat

    private var gradientColors: [Color] {
        switch work.genre {
        case .classical: [.indigo, .purple]
        case .filmScore: [.orange, .red]
        case .rock: [.gray, .black]
        case .jazz: [.blue, .cyan]
        default: [.teal, .green]
        }
    }

    private var iconName: String {
        switch work.workType {
        case .symphony: "waveform.path"
        case .soundtrack: "film"
        case .album: "opticaldisc"
        default: "music.note"
        }
    }

    var body: some View {
        if let artworkURL = work.artworkURL {
            AsyncImage(url: artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: height)
                        .clipped()
                default:
                    placeholder
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: iconName)
                .font(.system(size: height * 0.25))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


