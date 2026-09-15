import SwiftUI

/// Affiche une signature enregistrée.
///
/// Rendue en `.template` : le PNG est noir sur fond transparent, ce mode
/// le reteinte avec la couleur du texte et la garde lisible en mode sombre.
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
                .accessibilityLabel(signature.signerName.isEmpty
                                    ? "Signature"
                                    : "Signature de \(signature.signerName)")
        }
    }
}
