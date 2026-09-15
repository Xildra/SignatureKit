import XCTest
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

    /// Le piège d'origine : un `guard let else { return }` dans le setter
    /// laissait l'ancienne image en place quand on passait `nil`.
    func testAssigningNilErasesTheSignature() {
        var signature = Signature(image: makeImage(), strokeData: Data([1, 2, 3]))
        signature.image = nil
        XCTAssertFalse(signature.isSigned)
        XCTAssertNil(signature.signedAt)
        XCTAssertNil(signature.strokeData)
    }

    func testCodableRoundTrip() throws {
        let original = Signature(signerName: "Cpt Martin",
                                 image: makeImage(),
                                 strokeData: Data([1, 2, 3]))
        let decoded = try JSONDecoder().decode(Signature.self,
                                               from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.signerName, "Cpt Martin")
        XCTAssertEqual(decoded.strokeData, Data([1, 2, 3]))
    }
}
