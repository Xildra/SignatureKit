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

    func testUnreadableDataIsIgnored() {
        let controller = SignatureCanvasController()
        controller.canvasSizeChanged(to: canvasSize)
        controller.load(Data([1, 2, 3]))
        XCTAssertTrue(controller.isEmpty)
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
}
