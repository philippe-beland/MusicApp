import SwiftUI
import MusicKit

struct SongDetailView: View {
    let song: Song
    let album: Album
    @State private var comment: String = ""
    @State private var savedComment: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(song.title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(album.artist.name)
                .font(.title3)
                .foregroundColor(.secondary)

            if let duration = song.duration {
                Text("Durée : \(formatDuration(duration))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Divider()
            
            Text("Ajouter un commentaire :")
                .font(.headline)
            
            TextEditor(text: $comment)
                .frame(height: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
            
            Button("Enregistrer le commentaire") {
                savedComment = comment
            }
            .buttonStyle(.borderedProminent)
            
            if !savedComment.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Commentaire enregistré :")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(savedComment)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Détail Piste")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    // This would need a real MusicKit Song for preview
    Text("Song Detail View")
}
