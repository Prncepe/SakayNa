import SwiftUI
import UIKit

enum ReceiptPDFBuilder {
    @MainActor
    static func makeFile(
        booking: Booking,
        renterName: String,
        ownerName: String
    ) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SakayNa-Receipt-\(booking.id).pdf")
        try? FileManager.default.removeItem(at: url)

        let page = CGSize(width: 612, height: 792)
        let content = ReceiptDocumentView(
            booking: booking,
            renterName: renterName,
            ownerName: ownerName
        )
        .padding(32)
        .frame(width: 548)
        .background(Color.white)
        .environment(\.palette, ThemePalette.make(.light))

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: 548, height: 728)
        renderer.render { size, renderInContext in
            var mediaBox = CGRect(origin: .zero, size: page)
            guard let pdf = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else { return }
            pdf.beginPDFPage(nil)
            let scale = min(548 / max(size.width, 1), 728 / max(size.height, 1))
            pdf.saveGState()
            pdf.translateBy(x: 32, y: page.height - 32 - size.height * scale)
            pdf.scaleBy(x: scale, y: scale)
            renderInContext(pdf)
            pdf.restoreGState()
            pdf.endPDFPage()
            pdf.closePDF()
        }
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
