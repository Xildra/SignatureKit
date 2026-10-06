import XCTest
@testable import SignatureKit

final class SignatureCanvasControllerTests: XCTestCase {

    private let canvasSize = CGSize(width: 300, height: 150)

    private func draw(on controller: SignatureCanvasController,
                      from start: CGPoint, to end: CGPoint) {
        let time = Date()
        controller.begin(at: start, time: time)
        controller.extend(to: end, time: time.addingTimeInterval(0.1))
        controller.end()
    }

    func testStrokeIsCommittedOnEnd() {
        let controller = SignatureCanvasController()
        XCTAssertTrue(controller.isEmpty)

        draw(on: controller, from: .zero, to: CGPoint(x: 50, y: 0))

        XCTAssertEqual(controller.strokes.count, 1)
        XCTAssertEqual(controller.strokes[0].points.count, 2)
        XCTAssertTrue(controller.currentPoints.isEmpty)
        XCTAssertFalse(controller.isEmpty)
    }

    func testUndoThenRedo() {
        let controller = SignatureCanvasController()
        draw(on: controller, from: .zero, to: CGPoint(x: 50, y: 0))
        draw(on: controller, from: .zero, to: CGPoint(x: 0, y: 50))

        controller.undo()
        XCTAssertEqual(controller.strokes.count, 1)
        XCTAssertTrue(controller.canRedo)

        controller.redo()
        XCTAssertEqual(controller.strokes.count, 2)
        XCTAssertFalse(controller.canRedo)
    }

    func testNewStrokeInvalidatesRedo() {
        let controller = SignatureCanvasController()
        draw(on: controller, from: .zero, to: CGPoint(x: 50, y: 0))
        controller.undo()

        draw(on: controller, from: .zero, to: CGPoint(x: 0, y: 50))

        XCTAssertFalse(controller.canRedo)
        XCTAssertEqual(controller.strokes.count, 1)
    }

    func testClearEmptiesEverything() {
        let controller = SignatureCanvasController()
        draw(on: controller, from: .zero, to: CGPoint(x: 50, y: 0))
        draw(on: controller, from: .zero, to: CGPoint(x: 0, y: 50))
        controller.undo()

        controller.clear()

        XCTAssertTrue(controller.isEmpty)
        XCTAssertFalse(controller.canUndo)
        XCTAssertFalse(controller.canRedo)
    }

    func testEmptyControllerExportsNothing() {
        let controller = SignatureCanvasController()
        XCTAssertNil(controller.drawing())
        XCTAssertNil(controller.drawingData())
    }

    /// The sheet loads the existing signature before the drawing area has a
    /// size: the drawing has to wait, then fit itself to the real area.
    func testLoadBeforeLayoutIsAppliedOnceSizeIsKnown() throws {
        let saved = SignatureDrawing(canvasSize: CGSize(width: 100, height: 50),
                                     strokes: [SignatureStroke(points: [.init(x: 10, y: 10, width: 2)])])
        let controller = SignatureCanvasController()

        controller.load(try saved.data())
        XCTAssertTrue(controller.strokes.isEmpty)

        controller.canvasSizeChanged(to: CGSize(width: 200, height: 100))
        XCTAssertEqual(controller.strokes.first?.points.first, .init(x: 20, y: 20, width: 4))
    }

    func testDrawingDataReloadsIdentically() throws {
        let controller = SignatureCanvasController()
        controller.canvasSizeChanged(to: canvasSize)
        draw(on: controller, from: CGPoint(x: 10, y: 10), to: CGPoint(x: 120, y: 60))

        let reloaded = SignatureCanvasController()
        reloaded.canvasSizeChanged(to: canvasSize)
        reloaded.load(try XCTUnwrap(controller.drawingData()))

        XCTAssertEqual(reloaded.strokes, controller.strokes)
    }

    /// A controller kept by SwiftUI from one sheet to the next: the previous
    /// person's drawing, finished or still in progress, must not remain.
    func testLoadingNothingWipesThePreviousDrawing() {
        let controller = SignatureCanvasController()
        controller.canvasSizeChanged(to: canvasSize)
        draw(on: controller, from: CGPoint(x: 10, y: 10), to: CGPoint(x: 80, y: 40))
        controller.begin(at: CGPoint(x: 100, y: 50), time: Date())   // never ended

        controller.load(nil)

        XCTAssertTrue(controller.isEmpty)
        XCTAssertFalse(controller.canRedo)
    }

    func testUnreadableDataIsIgnored() {
        let controller = SignatureCanvasController()
        controller.canvasSizeChanged(to: canvasSize)
        controller.load(Data([1, 2, 3]))
        XCTAssertTrue(controller.isEmpty)
    }

    /// SwiftUI can report a transient size first — 76 pt wide at launch, seen
    /// on the simulator. A reloaded drawing must end up fitted to the final
    /// size instead of staying frozen at the first one.
    func testReloadedDrawingFollowsTheFinalSize() throws {
        let saved = SignatureDrawing(canvasSize: CGSize(width: 360, height: 240),
                                     strokes: [SignatureStroke(points: [.init(x: 180, y: 120, width: 4)])])
        let controller = SignatureCanvasController()

        controller.canvasSizeChanged(to: CGSize(width: 76, height: 240))
        controller.load(try saved.data())
        controller.canvasSizeChanged(to: CGSize(width: 360, height: 240))

        XCTAssertEqual(controller.strokes.first?.points.first, .init(x: 180, y: 120, width: 4))
    }

    /// Once the reloaded drawing is edited, the strokes on screen are the
    /// truth: a later size change must not bring back what was undone.
    func testEditedDrawingIsNotRefittedFromTheOriginal() throws {
        let saved = SignatureDrawing(canvasSize: CGSize(width: 360, height: 240),
                                     strokes: [SignatureStroke(points: [.init(x: 180, y: 120, width: 4)])])
        let controller = SignatureCanvasController()
        controller.canvasSizeChanged(to: CGSize(width: 360, height: 240))
        controller.load(try saved.data())

        controller.undo()
        controller.canvasSizeChanged(to: CGSize(width: 300, height: 240))

        XCTAssertTrue(controller.strokes.isEmpty)
    }

    @MainActor
    func testImageIsCroppedToTheStroke() throws {
        let controller = SignatureCanvasController()
        controller.canvasSizeChanged(to: canvasSize)
        draw(on: controller, from: CGPoint(x: 100, y: 50), to: CGPoint(x: 200, y: 50))

        let bounds = try XCTUnwrap(controller.drawing()?.bounds(margin: 12))
        let image = try XCTUnwrap(controller.image(scale: 2, margin: 12))

        XCTAssertEqual(image.size.width, bounds.width, accuracy: 1)
        XCTAssertEqual(image.size.height, bounds.height, accuracy: 1)
        XCTAssertLessThan(image.size.width, canvasSize.width)
    }

    @MainActor
    func testSmallAndLargeSignaturesHaveTheSamePixelSize() throws {
        let small = SignatureCanvasController()
        small.canvasSizeChanged(to: canvasSize)
        draw(on: small, from: CGPoint(x: 100, y: 50), to: CGPoint(x: 150, y: 50))

        let large = SignatureCanvasController()
        large.canvasSizeChanged(to: canvasSize)
        draw(on: large, from: CGPoint(x: 20, y: 50), to: CGPoint(x: 280, y: 50))

        let smallImage = try XCTUnwrap(small.image(scale: 2, margin: 12))
        let largeImage = try XCTUnwrap(large.image(scale: 2, margin: 12))

        // Both lines are horizontal: their width fills the canvas once scaled.
        XCTAssertEqual(smallImage.size.width * smallImage.scale,
                       largeImage.size.width * largeImage.scale,
                       accuracy: 2)
        XCTAssertGreaterThan(smallImage.scale, largeImage.scale)
    }
}
