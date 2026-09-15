import UIKit

/// Une signature manuscrite.
///
/// Deux représentations, volontairement :
/// - `pngData` pour l'affichage et l'insertion dans un PDF ;
/// - `strokeData` (vectoriel `PKDrawing`) comme original, rejouable et
///   ré-exportable à n'importe quelle résolution.
public struct Signature: Codable, Equatable, Sendable {

    public var signerName: String
    public private(set) var signedAt: Date?
    public private(set) var pngData: Data?
    public private(set) var strokeData: Data?

    public var image: UIImage? {
        get {
            guard let pngData else { return nil }
            return UIImage(data: pngData, scale: UITraitCollection.current.displayScale)
        }
        set {
            pngData = newValue?.pngData()
            signedAt = (pngData == nil) ? nil : Date()
            if newValue == nil { strokeData = nil }
        }
    }

    public var isSigned: Bool { pngData != nil }

    public init(signerName: String = "", image: UIImage? = nil, strokeData: Data? = nil) {
        self.signerName = signerName
        self.pngData = image?.pngData()
        self.strokeData = strokeData
        self.signedAt = (image == nil) ? nil : Date()
    }

    /// Pour reconstruire une signature venue d'une API ou d'une base.
    public init(signerName: String, pngData: Data?, strokeData: Data?, signedAt: Date?) {
        self.signerName = signerName
        self.pngData = pngData
        self.strokeData = strokeData
        self.signedAt = signedAt
    }

    public mutating func clear() {
        pngData = nil
        strokeData = nil
        signedAt = nil
        signerName = ""
    }
}
