import XCTest
import UIKit
@testable import SignatureKit

final class SignatureTests: XCTestCase {

    private func makeImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }

    func testEmptySignatureIsNotSigned() {
        XCTAssertFalse(Signature().isSigned)
        XCTAssertNil(Signature().signedAt)
    }

    func testAssigningAnImageMarksItSigned() {
        var signature = Signature()
        signature.image = makeImage()
        XCTAssertTrue(signature.isSigned)
        XCTAssertNotNil(signature.signedAt)
    }

    /// The original trap: a `guard let else { return }` in the setter left
    /// the previous image in place when `nil` was assigned.
    func testAssigningNilErasesTheSignature() {
        var signature = Signature(image: makeImage(), strokeData: Data([1, 2, 3]))
        signature.image = nil
        XCTAssertFalse(signature.isSigned)
        XCTAssertNil(signature.signedAt)
        XCTAssertNil(signature.strokeData)
    }

    func testEachSignatureGetsItsOwnIdentity() {
        XCTAssertNotEqual(Signature().id, Signature().id)
    }

    /// Wiping a signature keeps the row it belongs to: the identity has to
    /// survive so the app can store the new drawing in the same place.
    func testIdentitySurvivesClear() {
        var signature = Signature(image: makeImage())
        let id = signature.id

        signature.clear()

        XCTAssertEqual(signature.id, id)
        XCTAssertFalse(signature.isSigned)
    }

    func testCodableRoundTrip() throws {
        let original = Signature(image: makeImage(), strokeData: Data([1, 2, 3]))
        let decoded = try JSONDecoder().decode(Signature.self,
                                               from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.strokeData, Data([1, 2, 3]))
    }

    /// Signatures stored by earlier versions must stay readable: no `id`
    /// back then, and a `signerName` the package no longer knows about.
    func testDecodingASignatureSavedByAnEarlierVersion() throws {
        let json = Data(#"{"signerName":"Alex Dupont","strokeData":"AQID"}"#.utf8)

        let decoded = try JSONDecoder().decode(Signature.self, from: json)

        XCTAssertEqual(decoded.strokeData, Data([1, 2, 3]))
        XCTAssertFalse(decoded.isSigned)
        XCTAssertNotEqual(decoded.id,
                          try JSONDecoder().decode(Signature.self, from: json).id)
    }
}
