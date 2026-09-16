import SwiftUI

/// The package's SF Symbols, named after their role rather than their shape.
///
/// Internal: they are not added to `Image` in consuming apps, which stay free
/// to declare their own `Image.undo` without any conflict.
extension Image {
    static let undo = Image(systemName: "arrow.uturn.backward")
    static let redo = Image(systemName: "arrow.uturn.forward")
    static let clear = Image(systemName: "trash")
    static let privacy = Image(systemName: "hand.raised.fill")
}
