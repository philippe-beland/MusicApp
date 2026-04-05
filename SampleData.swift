import Foundation

enum SampleData {

    // MARK: - Artists

    static let beethoven = Artist(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Ludwig van Beethoven",
        sortName: "Beethoven, Ludwig van",
        type: .person,
        aliases: nil,
        genres: .classical,
        country: "Germany",
        beginDate: nil,
        endDate: nil,
        members: [],
        notes: "One of the greatest composers in Western music history."
    )

    static let zimmer = Artist(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Hans Zimmer",
        sortName: "Zimmer, Hans",
        type: .person,
        aliases: nil,
        genres: .filmScore,
        country: "Germany",
        beginDate: nil,
        endDate: nil,
        members: [],
        notes: "Academy Award-winning film composer."
    )

    static let pinkFloyd = Artist(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Pink Floyd",
        sortName: "Pink Floyd",
        type: .ensemble,
        aliases: nil,
        genres: .rock,
        country: "United Kingdom",
        beginDate: nil,
        endDate: nil,
        members: ["David Gilmour", "Roger Waters", "Nick Mason", "Richard Wright"],
        notes: "Pioneers of progressive and psychedelic rock."
    )

    static let milesDavis = Artist(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Miles Davis",
        sortName: "Davis, Miles",
        type: .person,
        aliases: nil,
        genres: .jazz,
        country: "United States",
        beginDate: nil,
        endDate: nil,
        members: [],
        notes: "Legendary jazz trumpeter and bandleader."
    )

    static let allArtists: [Artist] = [beethoven, zimmer, pinkFloyd, milesDavis]

    // MARK: - Works

    static let symphony5: Work = {
        var work = Work(
            id: UUID(uuidString: "00000000-0000-0000-0001-000000000001")!,
            artist: beethoven,
            title: "Symphony No. 5 in C minor",
            workType: .symphony,
            genre: .classical,
            country: "Austria",
            releaseDate: nil,
            opus: "Op. 67",
            premiereDate: nil,
            premiereLocation: "Theater an der Wien, Vienna",
            catalogue: nil,
            filmTitle: nil,
            director: nil,
            awards: [],
            label: nil,
            producer: nil,
            recordingStudio: nil,
            notes: "One of the best-known compositions in classical music.",
            pieces: []
        )
        work.pieces = [
            Piece(id: UUID(), Work: nil, title: "I. Allegro con brio", pieceNumber: 1,
                  keySignature: "C minor", timeSignature: "2/4", tempoBPM: 108, durationMS: 480_000,
                  files: [
                    File(id: UUID(), sourceType: .audio, storageURL: URL(string: "https://cdn.example.com/beethoven/symphony5/mv1.mp3")),
                    File(id: UUID(), sourceType: .pdfScore, storageURL: URL(string: "https://cdn.example.com/beethoven/symphony5/mv1.pdf")),
                  ]),
            Piece(id: UUID(), Work: nil, title: "II. Andante con moto", pieceNumber: 2,
                  keySignature: "A-flat major", timeSignature: "3/8", tempoBPM: 92, durationMS: 600_000,
                  files: [
                    File(id: UUID(), sourceType: .audio, storageURL: URL(string: "https://cdn.example.com/beethoven/symphony5/mv2.mp3")),
                  ]),
            Piece(id: UUID(), Work: nil, title: "III. Scherzo: Allegro", pieceNumber: 3,
                  keySignature: "C minor", timeSignature: "3/4", tempoBPM: 96, durationMS: 320_000),
            Piece(id: UUID(), Work: nil, title: "IV. Allegro", pieceNumber: 4,
                  keySignature: "C major", timeSignature: "4/4", tempoBPM: 84, durationMS: 680_000),
        ]
        return work
    }()

    static let interstellar: Work = {
        var work = Work(
            id: UUID(uuidString: "00000000-0000-0000-0001-000000000002")!,
            artist: zimmer,
            title: "Interstellar",
            workType: .soundtrack,
            genre: .filmScore,
            country: "United States",
            releaseDate: nil,
            opus: nil,
            premiereDate: nil,
            premiereLocation: nil,
            catalogue: nil,
            filmTitle: "Interstellar",
            director: "Christopher Nolan",
            awards: ["BAFTA Award for Best Film Music"],
            label: "WaterTower Music",
            producer: "Hans Zimmer",
            recordingStudio: "AIR Studios",
            notes: "Organ-driven score for Christopher Nolan's space epic.",
            pieces: []
        )
        work.pieces = [
            Piece(id: UUID(), Work: nil, title: "Dreaming of the Crash", pieceNumber: 1,
                  durationMS: 75_000),
            Piece(id: UUID(), Work: nil, title: "Cornfield Chase", pieceNumber: 2,
                  durationMS: 128_000),
            Piece(id: UUID(), Work: nil, title: "Day One", pieceNumber: 3,
                  durationMS: 295_000),
            Piece(id: UUID(), Work: nil, title: "Stay", pieceNumber: 4,
                  durationMS: 367_000),
            Piece(id: UUID(), Work: nil, title: "No Time for Caution", pieceNumber: 5,
                  durationMS: 225_000),
        ]
        return work
    }()

    static let darkSide: Work = {
        var work = Work(
            id: UUID(uuidString: "00000000-0000-0000-0001-000000000003")!,
            artist: pinkFloyd,
            title: "The Dark Side of the Moon",
            workType: .album,
            genre: .rock,
            country: "United Kingdom",
            releaseDate: nil,
            opus: nil,
            premiereDate: nil,
            premiereLocation: nil,
            catalogue: nil,
            filmTitle: nil,
            director: nil,
            awards: ["Grammy Award for Best Engineered Album"],
            label: "Harvest",
            producer: "Pink Floyd",
            recordingStudio: "Abbey Road Studios",
            notes: "One of the best-selling albums of all time.",
            pieces: []
        )
        work.pieces = [
            Piece(id: UUID(), Work: nil, title: "Speak to Me", pieceNumber: 1,
                  durationMS: 68_000),
            Piece(id: UUID(), Work: nil, title: "Breathe", pieceNumber: 2,
                  durationMS: 169_000),
            Piece(id: UUID(), Work: nil, title: "Time", pieceNumber: 3,
                  durationMS: 413_000),
            Piece(id: UUID(), Work: nil, title: "The Great Gig in the Sky", pieceNumber: 4,
                  durationMS: 284_000),
            Piece(id: UUID(), Work: nil, title: "Money", pieceNumber: 5,
                  durationMS: 382_000),
            Piece(id: UUID(), Work: nil, title: "Us and Them", pieceNumber: 6,
                  durationMS: 469_000),
        ]
        return work
    }()

    static let kindOfBlue: Work = {
        var work = Work(
            id: UUID(uuidString: "00000000-0000-0000-0001-000000000004")!,
            artist: milesDavis,
            title: "Kind of Blue",
            workType: .album,
            genre: .jazz,
            country: "United States",
            releaseDate: nil,
            opus: nil,
            premiereDate: nil,
            premiereLocation: nil,
            catalogue: nil,
            filmTitle: nil,
            director: nil,
            awards: ["Grammy Hall of Fame"],
            label: "Columbia",
            producer: "Teo Macero",
            recordingStudio: "Columbia 30th Street Studio",
            notes: "The best-selling jazz album of all time.",
            pieces: []
        )
        work.pieces = [
            Piece(id: UUID(), Work: nil, title: "So What", pieceNumber: 1,
                  keySignature: "D Dorian", timeSignature: "4/4", tempoBPM: 136, durationMS: 545_000,
                  files: [
                    File(id: UUID(), sourceType: .audio, storageURL: URL(string: "https://cdn.example.com/miles/kindofblue/so-what.mp3")),
                  ]),
            Piece(id: UUID(), Work: nil, title: "Freddie Freeloader", pieceNumber: 2,
                  keySignature: "B-flat major", timeSignature: "4/4", tempoBPM: 138, durationMS: 587_000,
                  files: [
                    File(id: UUID(), sourceType: .audio, storageURL: URL(string: "https://cdn.example.com/miles/kindofblue/freddie-freeloader.mp3")),
                  ]),
            Piece(id: UUID(), Work: nil, title: "Blue in Green", pieceNumber: 3,
                  keySignature: "D minor", timeSignature: "4/4", tempoBPM: 60, durationMS: 337_000),
            Piece(id: UUID(), Work: nil, title: "All Blues", pieceNumber: 4,
                  keySignature: "G Mixolydian", timeSignature: "6/4", tempoBPM: 138, durationMS: 694_000),
            Piece(id: UUID(), Work: nil, title: "Flamenco Sketches", pieceNumber: 5,
                  keySignature: "C major", timeSignature: "4/4", tempoBPM: 76, durationMS: 567_000),
        ]
        return work
    }()

    static let allWorks: [Work] = [symphony5, interstellar, darkSide, kindOfBlue]
}
