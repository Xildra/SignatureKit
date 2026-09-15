import SwiftUI

/// Détient le tracé et les actions : annuler, rétablir, effacer, exporter.
@Observable
public final class SignatureCanvasController {

    public private(set) var strokes: [SignatureStroke] = []
    public internal(set) var currentPoints: [SignatureStroke.Point] = []

    @ObservationIgnored private var redoStack: [SignatureStroke] = []
    @ObservationIgnored internal var canvasSize: CGSize = .zero
    @ObservationIgnored private var pendingDrawing: SignatureDrawing?

    /// Bornes de l'épaisseur du trait, en points.
    public var minimumWidth: CGFloat = 1.5
    public var maximumWidth: CGFloat = 5
    /// Vitesse (pt/s) au-delà de laquelle le trait atteint son épaisseur mini.
    public var speedForMinimumWidth: CGFloat = 2500

    public init() {}

    // MARK: - État

    public var isEmpty: Bool { strokes.isEmpty && currentPoints.isEmpty }
    public var canUndo: Bool { !strokes.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    // MARK: - Actions

    public func undo() {
        guard let last = strokes.popLast() else { return }
        redoStack.append(last)
    }

    public func redo() {
        guard let stroke = redoStack.popLast() else { return }
        strokes.append(stroke)
    }

    public func clear() {
        strokes.removeAll()
        currentPoints.removeAll()
        redoStack.removeAll()
    }

    // MARK: - Saisie

    @ObservationIgnored private var lastLocation: CGPoint?
    @ObservationIgnored private var lastTime: Date?
    @ObservationIgnored private var lastWidth: CGFloat = 0

    internal func begin(at location: CGPoint, time: Date) {
        lastLocation = location
        lastTime = time
        lastWidth = maximumWidth
        currentPoints = [.init(x: location.x, y: location.y, width: maximumWidth)]
    }

    internal func extend(to location: CGPoint, time: Date) {
        guard let lastLocation, let lastTime else {
            begin(at: location, time: time)
            return
        }

        let distance = hypot(location.x - lastLocation.x, location.y - lastLocation.y)
        // On filtre les points trop rapprochés : moins de bruit, moins de data.
        guard distance > 1 else { return }

        let elapsed = max(time.timeIntervalSince(lastTime), 1.0 / 240)
        let speed = distance / CGFloat(elapsed)
        let ratio = min(1, speed / speedForMinimumWidth)
        let target = maximumWidth - (maximumWidth - minimumWidth) * ratio

        // Lissage : sans ça l'épaisseur saute à chaque changement de vitesse.
        let width = lastWidth * 0.6 + target * 0.4

        currentPoints.append(.init(x: location.x, y: location.y, width: width))
        self.lastLocation = location
        self.lastTime = time
        self.lastWidth = width
    }

    internal func end() {
        defer {
            currentPoints = []
            lastLocation = nil
            lastTime = nil
        }
        guard !currentPoints.isEmpty else { return }
        strokes.append(SignatureStroke(points: currentPoints))
        redoStack.removeAll()   // un nouveau trait invalide le rétablissement
    }

    // MARK: - Chargement / export

    /// Recharge un tracé existant. Il sera remis à l'échelle de la zone
    /// dès que celle-ci est connue.
    public func load(_ data: Data?) {
        guard let data, let drawing = try? SignatureDrawing(data: data) else { return }
        if canvasSize == .zero {
            pendingDrawing = drawing
        } else {
            strokes = drawing.scaled(to: canvasSize).strokes
        }
    }

    internal func canvasSizeChanged(to size: CGSize) {
        canvasSize = size
        if let pendingDrawing {
            strokes = pendingDrawing.scaled(to: size).strokes
            self.pendingDrawing = nil
        }
    }

    public func drawing() -> SignatureDrawing? {
        guard !strokes.isEmpty else { return nil }
        return SignatureDrawing(canvasSize: canvasSize, strokes: strokes)
    }

    public func drawingData() -> Data? {
        try? drawing()?.data()
    }

    /// PNG transparent recadré au plus près du tracé.
    @MainActor
    public func image(ink: Color = .black, scale: CGFloat = 3, margin: CGFloat = 12) -> UIImage? {
        guard !strokes.isEmpty,
              let bounds = SignatureDrawing(canvasSize: canvasSize, strokes: strokes)
                  .bounds(margin: margin),
              bounds.width > 0, bounds.height > 0 else { return nil }

        let content = SignatureStrokesView(strokes: strokes, ink: ink)
            .frame(width: canvasSize.width, height: canvasSize.height)
            .offset(x: -bounds.minX, y: -bounds.minY)
            .frame(width: bounds.width, height: bounds.height, alignment: .topLeading)
            .clipped()

        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage
    }
}

/// La zone de dessin nue, si tu veux composer ta propre interface autour.
///
/// Full SwiftUI : aucun `UIViewRepresentable`, donc elle se place où tu veux,
/// y compris dans une `ScrollView`.
public struct SignatureCanvas: View {

    private let controller: SignatureCanvasController
    private let ink: Color

    public init(controller: SignatureCanvasController, ink: Color = .black) {
        self.controller = controller
        self.ink = ink
    }

    public var body: some View {
        ZStack {
            SignatureStrokesView(strokes: controller.strokes, ink: ink)
            SignatureStrokesView(strokes: [SignatureStroke(points: controller.currentPoints)], ink: ink)
        }
        .contentShape(Rectangle())
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
            controller.canvasSizeChanged(to: size)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if controller.currentPoints.isEmpty {
                        controller.begin(at: clamped(value.location), time: value.time)
                    } else {
                        controller.extend(to: clamped(value.location), time: value.time)
                    }
                }
                .onEnded { _ in controller.end() }
        )
    }

    private func clamped(_ point: CGPoint) -> CGPoint {
        let size = controller.canvasSize
        guard size != .zero else { return point }
        return CGPoint(x: min(max(0, point.x), size.width),
                       y: min(max(0, point.y), size.height))
    }
}
