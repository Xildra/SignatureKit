import XCTest
import SwiftData
import UIKit
@testable import SignatureKit

/// The model belongs to the app, so this one stands in for it: a `Signature`
/// is stored as a plain property, and only this class goes into the schema.
@Model
final class TestDocument {
    var signatures: [Signature] = []

    init(signatures: [Signature] = []) {
        self.signatures = signatures
    }
}

/// Backs the README's claim that a `Signature` is stored as it is. The store
/// is written to disk and reopened from a second container: an in-memory one
/// would prove nothing about what actually lands in the file.
final class SignaturePersistenceTests: XCTestCase {

    private var storeURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        storeURL = FileManager.default.temporaryDirectory
            .appending(path: "\(UUID().uuidString).store")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: storeURL)
        try super.tearDownWithError()
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: TestDocument.self,
                           configurations: ModelConfiguration(url: storeURL))
    }

    private func makeImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }

    @MainActor
    func testSignaturesSurviveAReopenedStore() throws {
        let saved = Signature(image: makeImage(), strokeData: Data([1, 2, 3]))

        let container = try makeContainer()
        container.mainContext.insert(TestDocument(signatures: [saved]))
        try container.mainContext.save()

        // A second container on the same file: nothing is left in memory.
        let reopened = try makeContainer()
        let documents = try reopened.mainContext.fetch(FetchDescriptor<TestDocument>())

        XCTAssertEqual(documents.count, 1)
        let reloaded = try XCTUnwrap(documents.first?.signatures.first)
        XCTAssertEqual(reloaded.id, saved.id)
        XCTAssertEqual(reloaded.pngData, saved.pngData)
        XCTAssertEqual(reloaded.strokeData, saved.strokeData)
        XCTAssertEqual(try XCTUnwrap(reloaded.signedAt).timeIntervalSince1970,
                       try XCTUnwrap(saved.signedAt).timeIntervalSince1970,
                       accuracy: 0.001)
        XCTAssertTrue(reloaded.isSigned)
    }

    /// `Signature` is a value type: editing one in place has to mark the
    /// model dirty, otherwise the change never reaches the store.
    @MainActor
    func testEditingASignatureInPlaceIsSaved() throws {
        let container = try makeContainer()
        let document = TestDocument(signatures: [Signature(image: makeImage())])
        container.mainContext.insert(document)
        try container.mainContext.save()

        document.signatures[0].clear()
        try container.mainContext.save()

        let reopened = try makeContainer()
        let reloaded = try XCTUnwrap(
            reopened.mainContext.fetch(FetchDescriptor<TestDocument>()).first?.signatures.first
        )
        XCTAssertFalse(reloaded.isSigned)
    }
}
