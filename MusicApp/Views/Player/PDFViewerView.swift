import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let url: URL
    @State private var pdfDocument: PDFDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading PDF...")
            } else if let doc = pdfDocument {
                PDFKitView(document: doc)
            } else {
                ContentUnavailableView(
                    "Could not load PDF",
                    systemImage: "doc.questionmark",
                    description: Text(errorMessage ?? "Unknown error")
                )
            }
        }
        .navigationTitle("Score")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadPDF() }
    }

    private func loadPDF() async {
        isLoading = true
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let doc = PDFDocument(data: data) {
                pdfDocument = doc
            } else {
                errorMessage = "Invalid PDF data."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = document
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}
