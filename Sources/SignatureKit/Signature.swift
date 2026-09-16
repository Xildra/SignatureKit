import UIKit

/// A handwritten signature.
///
/// Two representations, on purpose:
/// - `pngData` for display and for embedding in a PDF;
/// - `strokeData` (a `SignatureDrawing` encoded as JSON) as the original:
///   replayable, and re-exportable at any resolution.
///
/// Who signed is not part of it: names, roles and relationships belong to
/// the app. `Codable` and `Identifiable`, so a signature is stored as it is —
/// inside a model owned by the app, in JSON, or sent to an API.
public struct Signature: Codable, Equatable, Identifiable, Sendable {

    /// Stable identity, created once and kept for the whole life of the
    /// signature, `clear()` included: a signature wiped and drawn again is
    /// still the same one.
    public let id: UUID

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

    public init(id: UUID = UUID(), image: UIImage? = nil, strokeData: Data? = nil) {
        self.id = id
        self.pngData = image?.pngData()
        self.strokeData = strokeData
        self.signedAt = (image == nil) ? nil : Date()
    }

    /// Rebuilds a signature that came from an API or a database.
    public init(id: UUID = UUID(), pngData: Data?, strokeData: Data?, signedAt: Date?) {
        self.id = id
        self.pngData = pngData
        self.strokeData = strokeData
        self.signedAt = signedAt
    }

    public mutating func clear() {
        pngData = nil
        strokeData = nil
        signedAt = nil
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, signedAt, pngData, strokeData
    }

    /// Signatures encoded by earlier versions stay readable: a missing `id`
    /// is replaced by a fresh one, and keys that no longer exist are ignored.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        signedAt = try container.decodeIfPresent(Date.self, forKey: .signedAt)
        pngData = try container.decodeIfPresent(Data.self, forKey: .pngData)
        strokeData = try container.decodeIfPresent(Data.self, forKey: .strokeData)
    }
}
