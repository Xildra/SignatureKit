import SwiftUI

/// Displays a saved signature.
///
/// Rendered as `.template`: the PNG is black on transparent, and that mode
/// re-tints it with the text color, keeping it readable in dark mode.
public struct SignatureThumbnail: View {

    private let signature: Signature
    private let height: CGFloat

    public init(_ signature: Signature, height: CGFloat = 50) {
        self.signature = signature
        self.height = height
    }

    public var body: some View {
        if let image = signature.image {
            Image(uiImage: image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary)
                .frame(height: height)
                // An app that knows who signed can override this label.
                .accessibilityLabel(Text(.signature))
        }
    }
}
