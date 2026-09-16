import SwiftUI

/// Everything that tells one signature box from another.
public struct SignaturePadConfiguration: Sendable {

    public var title: String
    public var subtitle: String
    /// Existing signature to reopen for a touch-up rather than redoing it all.
    public var existing: Signature?

    public var ink: Color
    public var minimumWidth: CGFloat
    public var maximumWidth: CGFloat
    /// 3 ≈ 300 dpi: clean in print and in PDF.
    public var exportScale: CGFloat
    public var exportMargin: CGFloat

    public init(title: String,
                subtitle: String = "",
                existing: Signature? = nil,
                ink: Color = .black,
                minimumWidth: CGFloat = 1.5,
                maximumWidth: CGFloat = 5,
                exportScale: CGFloat = 3,
                exportMargin: CGFloat = 12) {
        self.title = title
        self.subtitle = subtitle
        self.existing = existing
        self.ink = ink
        self.minimumWidth = minimumWidth
        self.maximumWidth = maximumWidth
        self.exportScale = exportScale
        self.exportMargin = exportMargin
    }
}
