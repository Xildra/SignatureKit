import CoreGraphics
import Foundation

/// Un trait : une suite de points, chacun avec son épaisseur locale.
/// L'épaisseur vient de la vitesse du geste — c'est ce qui donne un tracé
/// vivant plutôt qu'un trait de feutre uniforme.
public struct SignatureStroke: Codable, Equatable, Sendable {

    public struct Point: Codable, Equatable, Sendable {
        public var x: CGFloat
        public var y: CGFloat
        public var width: CGFloat

        enum CodingKeys: String, CodingKey {
            case x, y, width = "w"
        }

        public init(x: CGFloat, y: CGFloat, width: CGFloat) {
            self.x = x
            self.y = y
            self.width = width
        }

        public var cgPoint: CGPoint { CGPoint(x: x, y: y) }
    }

    public var points: [Point]

    public init(points: [Point] = []) { self.points = points }
}

/// Le tracé complet, plus la taille de la zone où il a été saisi.
///
/// Sans cette taille, recharger une signature sur un pad de dimensions
/// différentes (iPhone puis iPad) la placerait n'importe où.
public struct SignatureDrawing: Codable, Equatable, Sendable {

    public var canvasSize: CGSize
    public var strokes: [SignatureStroke]

    public init(canvasSize: CGSize, strokes: [SignatureStroke]) {
        self.canvasSize = canvasSize
        self.strokes = strokes
    }

    public init(data: Data) throws {
        self = try JSONDecoder().decode(SignatureDrawing.self, from: data)
    }

    public func data() throws -> Data {
        try JSONEncoder().encode(self)
    }

    /// Replace le tracé dans une zone d'une autre taille, sans le déformer.
    public func scaled(to size: CGSize) -> SignatureDrawing {
        guard canvasSize.width > 0, canvasSize.height > 0,
              size.width > 0, size.height > 0 else { return self }

        let ratio = min(size.width / canvasSize.width, size.height / canvasSize.height)
        guard ratio != 1 else { return self }

        let scaled = strokes.map { stroke in
            SignatureStroke(points: stroke.points.map {
                .init(x: $0.x * ratio, y: $0.y * ratio, width: $0.width * ratio)
            })
        }
        return SignatureDrawing(canvasSize: size, strokes: scaled)
    }

    /// Boîte englobante du tracé, épaisseurs comprises.
    public func bounds(margin: CGFloat = 0) -> CGRect? {
        let points = strokes.flatMap(\.points)
        guard let first = points.first else { return nil }

        var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
        for point in points {
            let radius = point.width / 2
            minX = min(minX, point.x - radius); maxX = max(maxX, point.x + radius)
            minY = min(minY, point.y - radius); maxY = max(maxY, point.y + radius)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            .insetBy(dx: -margin, dy: -margin)
    }
}
