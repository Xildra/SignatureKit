import SwiftUI

/// Holds the strokes and the actions: undo, redo, clear, export.
@Observable
public final class SignatureCanvasController {

    public private(set) var strokes: [SignatureStroke] = []
    public internal(set) var currentPoints: [SignatureStroke.Point] = []

    @ObservationIgnored private var redoStack: [SignatureStroke] = []
    @ObservationIgnored internal var canvasSize: CGSize = .zero
    /// The drawing as reloaded, kept while it is untouched: every new size is
    /// fitted from this original, never from an already scaled copy.
    @ObservationIgnored private var loadedDrawing: SignatureDrawing?

    /// Stroke width bounds, in points.
    public var minimumWidth: CGFloat = 1.5
    public var maximumWidth: CGFloat = 5
    /// Speed (pt/s) beyond which the stroke reaches its minimum width.
    public var speedForMinimumWidth: CGFloat = 2500

    public init() {}

    // MARK: - State

    public var isEmpty: Bool { strokes.isEmpty && currentPoints.isEmpty }
    public var canUndo: Bool { !strokes.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    // MARK: - Actions

    public func undo() {
        guard let last = strokes.popLast() else { return }
        redoStack.append(last)
        loadedDrawing = nil
    }

    public func redo() {
        guard let stroke = redoStack.popLast() else { return }
        strokes.append(stroke)
        loadedDrawing = nil
    }

    public func clear() {
        strokes.removeAll()
        currentPoints.removeAll()
        redoStack.removeAll()
        loadedDrawing = nil
    }

    // MARK: - Input

    @ObservationIgnored private var lastLocation: CGPoint?
    @ObservationIgnored private var lastTime: Date?
    @ObservationIgnored private var lastWidth: CGFloat = 0

    internal func begin(at location: CGPoint, time: Date) {
        lastLocation = location
        lastTime = time
        lastWidth = maximumWidth
        loadedDrawing = nil
        currentPoints = [.init(x: location.x, y: location.y, width: maximumWidth)]
    }

    internal func extend(to location: CGPoint, time: Date) {
        guard let lastLocation, let lastTime else {
            begin(at: location, time: time)
            return
        }

        let distance = hypot(location.x - lastLocation.x, location.y - lastLocation.y)
        // Points too close together are dropped: less noise, less data.
        guard distance > 1 else { return }

        let elapsed = max(time.timeIntervalSince(lastTime), 1.0 / 240)
        let speed = distance / CGFloat(elapsed)
        let ratio = min(1, speed / speedForMinimumWidth)
        let target = maximumWidth - (maximumWidth - minimumWidth) * ratio

        // Smoothing: without it the width jumps at every change of speed.
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
        redoStack.removeAll()   // a new stroke invalidates redo
    }

    // MARK: - Loading and export

    /// Reloads an existing drawing, fitted to the drawing area as soon as that
    /// area's size is known.
    public func load(_ data: Data?) {
        guard let data, let drawing = try? SignatureDrawing(data: data) else { return }
        loadedDrawing = drawing
        fitLoadedDrawing()
    }

    internal func canvasSizeChanged(to size: CGSize) {
        canvasSize = size
        fitLoadedDrawing()
    }

    /// SwiftUI can report transient sizes first — 76 pt wide at launch, before
    /// the real 370 pt. Fitting once would freeze the drawing at that first
    /// size, so an untouched reloaded drawing is re-fitted from its original
    /// on every change.
    private func fitLoadedDrawing() {
        guard let loadedDrawing, canvasSize.width > 0, canvasSize.height > 0 else { return }
        strokes = loadedDrawing.scaled(to: canvasSize).strokes
    }

    public func drawing() -> SignatureDrawing? {
        guard !strokes.isEmpty else { return nil }
        return SignatureDrawing(canvasSize: canvasSize, strokes: strokes)
    }

    public func drawingData() -> Data? {
        try? drawing()?.data()
    }

    /// Transparent PNG, cropped tight around the strokes.
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

/// The bare drawing area, to build your own interface around it.
///
/// Full SwiftUI: no `UIViewRepresentable`, so it fits anywhere, including
/// inside a `ScrollView`.
public struct SignatureCanvas: View {

    private let controller: SignatureCanvasController
    private let ink: Color

    public init(controller: SignatureCanvasController, ink: Color = .black) {
        self.controller = controller
        self.ink = ink
    }

    public var body: some View {
        ZStack {
            // An empty canvas draws nothing, and a stack with no content is
            // zero-sized: its touch area would be 0×0, so the first stroke could
            // never begin. `Color.clear` makes the stack fill the space it is
            // given from the start.
            Color.clear
            SignatureStrokesView(strokes: controller.strokes, ink: ink)
            SignatureStrokesView(strokes: [SignatureStroke(points: controller.currentPoints)], ink: ink)
        }
        .contentShape(Rectangle())
        .accessibilityElement()
        .accessibilityLabel(Text(.signatureArea))
        .accessibilityValue(controller.isEmpty ? Text(.empty) : Text(.signed))
        .accessibilityHint(Text(.drawYourSignatureWithYourFinger))
        // Without this trait, VoiceOver swallows the gesture and nothing is drawn.
        .accessibilityAddTraits(.allowsDirectInteraction)
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
