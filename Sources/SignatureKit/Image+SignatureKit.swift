import SwiftUI

/// The package's SF Symbols, named after their role rather than their shape.
///
/// `undo`, `redo` and `clear` share their names with catalog entries, and
/// `Text` also accepts an `Image`: `Text(.undo)` silently shows the icon
/// instead of the translated title. Where both exist, spell the type out —
/// `Text(LocalizedStringResource.undo)`.
///
/// Internal: they are not added to `Image` in consuming apps.
extension Image {
    static let undo = Image(systemName: "arrow.uturn.backward")
    static let redo = Image(systemName: "arrow.uturn.forward")
    static let clear = Image(systemName: "trash")
    static let privacy = Image(systemName: "hand.raised.fill")
}
