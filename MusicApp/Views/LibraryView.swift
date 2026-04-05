import SwiftUI

enum LibraryTab: String, CaseIterable {
    case works = "Works"
    case artists = "Artists"
}

struct LibraryView: View {
    @Environment(DataProvider.self) private var dataProvider
    @State private var selectedTab: LibraryTab = .works

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    ForEach(LibraryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .works:
                    WorksListView(works: dataProvider.works)
                case .artists:
                    ArtistsListView(artists: dataProvider.artists, works: dataProvider.works)
                }
            }
            .navigationTitle("Library")
        }
    }
}

// MARK: - Works List

struct WorksListView: View {
    let works: [Work]

    var body: some View {
        List(works) { work in
            NavigationLink(destination: WorkDetailView(work: work)) {
                WorkListRow(work: work)
            }
        }
        .listStyle(.plain)
    }
}

struct WorkListRow: View {
    let work: Work

    var body: some View {
        HStack(spacing: 14) {
            WorkArtworkPlaceholder(work: work, height: 56)
                .frame(width: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(work.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(work.artist.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(work.workType.rawValue.capitalized)
                    Text("·")
                    Text(work.genre.rawValue.capitalized)
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Artists List

struct ArtistsListView: View {
    let artists: [Artist]
    let works: [Work]

    var body: some View {
        List(artists) { artist in
            NavigationLink(destination: ArtistDetailView(artist: artist, works: works.filter { $0.artist.id == artist.id })) {
                ArtistListRow(artist: artist)
            }
        }
        .listStyle(.plain)
    }
}

struct ArtistListRow: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 14) {
            ArtistAvatarPlaceholder(artist: artist, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.body.weight(.medium))
                Text(artist.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Artist Avatar

struct ArtistAvatarPlaceholder: View {
    let artist: Artist
    let size: CGFloat

    private var color: Color {
        switch artist.genres {
        case .classical: .indigo
        case .filmScore: .orange
        case .rock: .gray
        case .jazz: .blue
        default: .teal
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.gradient)
            Text(String(artist.name.prefix(1)))
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    LibraryView()
        .environment(DataProvider())
}
