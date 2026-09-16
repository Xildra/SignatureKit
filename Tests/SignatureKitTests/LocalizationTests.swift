import XCTest
@testable import SignatureKit

/// Checks that every label has its French translation in the package bundle.
/// Going through the generated symbols keeps this test in step with the
/// catalog: a renamed or deleted entry no longer compiles.
final class LocalizationTests: XCTestCase {

    private func french(_ resource: LocalizedStringResource) -> String {
        var resource = resource
        resource.locale = Locale(identifier: "fr")
        return String(localized: resource)
    }

    func testEveryLabelIsTranslatedToFrench() {
        XCTAssertEqual(french(.cancel), "Annuler")
        XCTAssertEqual(french(.clear), "Tout effacer")
        XCTAssertEqual(french(.done), "Valider")
        XCTAssertEqual(french(.drawYourSignatureWithYourFinger), "Tracez la signature avec le doigt")
        XCTAssertEqual(french(.empty), "Vide")
        XCTAssertEqual(french(.redo), "Rétablir")
        XCTAssertEqual(french(.signAboveTheLine), "Signez au-dessus de la ligne")
        XCTAssertEqual(french(.signature), "Signature")
        XCTAssertEqual(french(.signatureArea), "Zone de signature")
        XCTAssertEqual(french(.signed), "Signée")
        XCTAssertEqual(french(.undo), "Annuler le trait")
    }
}
