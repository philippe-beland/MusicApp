import SwiftUI
import PDFKit
import WebKit

struct PDFViewerView: View {
    let url: URL
    @State private var pdfDocument: PDFDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var currentPage = 0
    @State private var pageCount = 0

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading PDF...")
            } else if let doc = pdfDocument {
                ZStack(alignment: .bottom) {
                    TabView(selection: $currentPage) {
                        ForEach(0..<pageCount, id: \.self) { index in
                            PDFPageView(document: doc, pageIndex: index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    if pageCount > 1 {
                        Text("\(currentPage + 1) / \(pageCount)")
                            .font(.caption)
                            .monospacedDigit()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 8)
                    }
                }
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
                pageCount = doc.pageCount
            } else {
                errorMessage = "Invalid PDF data."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// Renders a single PDF page as an image to avoid PDFKit Metal crashes.
struct PDFPageView: View {
    let document: PDFDocument
    let pageIndex: Int

    var body: some View {
        GeometryReader { geo in
            if let image = renderPage(size: geo.size) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func renderPage(size: CGSize) -> UIImage? {
        guard let page = document.page(at: pageIndex) else { return nil }
        let pageRect = page.bounds(for: .mediaBox)

        let scale = min(size.width / pageRect.width, size.height / pageRect.height)
        let renderSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

        let renderer = UIGraphicsImageRenderer(size: renderSize)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: renderSize))

            ctx.cgContext.translateBy(x: 0, y: renderSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)

            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }
}
