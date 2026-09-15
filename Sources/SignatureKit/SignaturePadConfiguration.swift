import SwiftUI

/// Tout ce qui distingue une case à signer d'une autre.
public struct SignaturePadConfiguration: Sendable {

    public var title: String
    public var subtitle: String
    /// Nom prérempli quand on sait déjà qui signe.
    public var signerName: String
    /// `false` masque le champ : une saisie de moins avant de signer.
    public var asksForName: Bool
    /// Noms proposés en un tap. Utile quand la même personne signe deux fois
    /// à des titres différents et qu'on ignore de qui il s'agit.
    public var suggestedNames: [String]
    /// Signature existante à rouvrir pour retouche plutôt que tout refaire.
    public var existing: Signature?

    public var ink: Color
    public var minimumWidth: CGFloat
    public var maximumWidth: CGFloat
    /// 3 ≈ 300 dpi : propre à l'impression et en PDF.
    public var exportScale: CGFloat
    public var exportMargin: CGFloat

    public init(title: String,
                subtitle: String = "",
                signerName: String = "",
                asksForName: Bool = true,
                suggestedNames: [String] = [],
                existing: Signature? = nil,
                ink: Color = .black,
                minimumWidth: CGFloat = 1.5,
                maximumWidth: CGFloat = 5,
                exportScale: CGFloat = 3,
                exportMargin: CGFloat = 12) {
        self.title = title
        self.subtitle = subtitle
        self.signerName = signerName
        self.asksForName = asksForName
        self.suggestedNames = suggestedNames
        self.existing = existing
        self.ink = ink
        self.minimumWidth = minimumWidth
        self.maximumWidth = maximumWidth
        self.exportScale = exportScale
        self.exportMargin = exportMargin
    }
}
