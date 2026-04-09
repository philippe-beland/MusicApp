import SwiftUI

struct HomeView: View {
    @Environment(DataProvider.self) private var dataProvider

    var body: some View {
        NavigationStack {
            ScrollView {
                if dataProvider.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if dataProvider.works.isEmpty {
                    ContentUnavailableView("No Works", systemImage: "music.note",
                        description: Text("Add works to your library to see them here."))
                } else {
                    VStack(alignment: .leading, spacing: 28) {
                        // Featured work
                        if let featured = dataProvider.works.first {
                            FeaturedWorkCard(work: featured)
                                .padding(.horizontal)
                        }

                        WorkCarousel(title: "Recently Listened", works: dataProvider.works)
                        WorkCarousel(title: "Recently Analyzed", works: Array(dataProvider.works.reversed()))
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Home")
        }
    }
}

// MARK: - Featured Card

struct FeaturedWorkCard: View {
    let work: Work

    var body: some View {
        NavigationLink(destination: WorkDetailView(work: work)) {
            ZStack(alignment: .bottomLeading) {
                WorkArtworkPlaceholder(work: work, height: 200)

                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(work.title)
                        .font(.title2.bold())
                    Text(work.artist.name)
                        .font(.subheadline)
                }
                .foregroundStyle(.white)
                .padding()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

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

#Preview {
    HomeView()
        .environment(DataProvider())
}
