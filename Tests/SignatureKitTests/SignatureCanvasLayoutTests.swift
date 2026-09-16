import XCTest
import SwiftUI
@testable import SignatureKit

/// An empty canvas draws nothing, and a SwiftUI stack with no content is
/// zero-sized. Its touch area would then be 0×0: the first stroke could never
/// be drawn, and since no stroke is ever drawn the canvas stays empty. The
/// canvas has to fill the space it is given even while empty.
@MainActor
final class SignatureCanvasLayoutTests: XCTestCase {

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    /// Lays the view out for real: `onGeometryChange` only reports a size
    /// once the view is in a window.
    private func layOut(_ view: some View, in size: CGSize) {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        self.window = window

        // The geometry action lands on a later turn of the run loop.
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }

    func testEmptyCanvasFillsTheSpaceItIsGiven() {
        let controller = SignatureCanvasController()
        let size = CGSize(width: 300, height: 240)

        layOut(SignatureCanvas(controller: controller)
            .frame(width: size.width, height: size.height), in: size)

        XCTAssertEqual(controller.canvasSize, size)
    }

    func testCanvasWithAStrokeAlsoFillsTheSpace() {
        let controller = SignatureCanvasController()
        let size = CGSize(width: 300, height: 240)
        controller.canvasSizeChanged(to: size)
        controller.begin(at: CGPoint(x: 10, y: 10), time: Date())
        controller.end()

        layOut(SignatureCanvas(controller: controller)
            .frame(width: size.width, height: size.height), in: size)

        XCTAssertEqual(controller.canvasSize, size)
    }
}
