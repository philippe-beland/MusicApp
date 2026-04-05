import SwiftUI

struct ArtistDetailView: View {
    let artist: Artist
    let works: [Work]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Artist header
                VStack(spacing: 12) {
                    ArtistAvatarPlaceholder(artist: artist, size: 120)

                    Text(artist.name)
                        .font(.title.bold())

                    HStack(spacing: 12) {
                        Label(artist.type.rawValue.capitalized, systemImage: "person")
                        if let country = artist.country {
                            Label(country, systemImage: "globe")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)

                // Notes
                if let notes = artist.notes {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                // Members
                if !artist.members.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Members")
                            .font(.title3.bold())
                        ForEach(artist.members, id: \.self) { member in
                            Label(member, systemImage: "person.fill")
                                .font(.body)
                        }
                    }
                    .padding(.horizontal)
                }

                // Works by this artist
                if !works.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Works")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        ForEach(works) { work in
                            NavigationLink(destination: WorkDetailView(work: work)) {
                                WorkListRow(work: work)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom)
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ArtistDetailView(
            artist: SampleData.pinkFloyd,
            works: [SampleData.darkSide]
        )
    }
}
