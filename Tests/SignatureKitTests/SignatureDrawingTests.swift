import XCTest
@testable import SignatureKit

final class SignatureDrawingTests: XCTestCase {

    private let drawing = SignatureDrawing(
        canvasSize: CGSize(width: 100, height: 50),
        strokes: [SignatureStroke(points: [.init(x: 10, y: 20, width: 2),
                                           .init(x: 40, y: 30, width: 4)])]
    )

    func testJSONRoundTrip() throws {
        XCTAssertEqual(try SignatureDrawing(data: drawing.data()), drawing)
    }

    /// The short key is part of the stored format: changing it would make
    /// already saved drawings unreadable.
    func testPointWidthIsEncodedUnderShortKey() throws {
        let json = try XCTUnwrap(String(data: drawing.data(), encoding: .utf8))
        XCTAssertTrue(json.contains("\"w\""))
    }

    func testScalingKeepsProportions() {
        // min(300 / 100, 300 / 50) = 3
        let scaled = drawing.scaled(to: CGSize(width: 300, height: 300))
        XCTAssertEqual(scaled.canvasSize, CGSize(width: 300, height: 300))
        XCTAssertEqual(scaled.strokes[0].points[1], .init(x: 120, y: 90, width: 12))
    }

    func testScalingToAnEmptySizeChangesNothing() {
        XCTAssertEqual(drawing.scaled(to: .zero), drawing)
    }

    func testBoundsIncludeStrokeWidthAndMargin() throws {
        let bounds = try XCTUnwrap(drawing.bounds(margin: 5))
        // x: 10 - 1 → 40 + 2; y: 20 - 1 → 30 + 2; then a 5 pt margin.
        XCTAssertEqual(bounds, CGRect(x: 4, y: 14, width: 43, height: 23))
    }

    func testEmptyDrawingHasNoBounds() {
        XCTAssertNil(SignatureDrawing(canvasSize: .zero, strokes: []).bounds())
    }
}
