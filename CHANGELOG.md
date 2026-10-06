# Changelog

Semantic versioning. Once two projects depend on it, the rule matters more
than the number:

- **major**: a public API renamed, removed, or with a changed signature.
  Breaks the build for everyone else.
- **minor**: a purely additive change (new parameter with a default value,
  new type, new view).
- **patch**: a behavior fix, API unchanged.

## [Unreleased]

- Fixed: a reopened signature could not be reset. Clearing it left Done
  disabled; confirming an emptied signature now returns it unsigned
  (`isSigned == false`), with its `id` kept.
- Fixed: the signature returned on confirmation got a new `id` instead of
  keeping the reopened one's.
- Fixed: a signature drawn small came out blurry once shown at a fixed
  height, a large one sharp. The PNG is now rendered at a scale that gives
  every signature about the same pixel size.

## [1.0.3]

- Fixed: the undo, redo and clear buttons showed their icon twice and never
  their title — an `Image` constant shared its name with the catalog entry,
  and `Text(.undo)` picked the image. The buttons now show their icon only,
  with the title kept for VoiceOver.
- Fixed: a reopened signature was shrunk. SwiftUI first reports a transient
  size (76 pt wide instead of 370), the reloaded drawing was fitted to it once
  and never again — and saved that way on confirmation. An untouched reloaded
  drawing is now re-fitted from its original on every size change.
- Tests guarding the re-fit, and that an edited drawing is never re-fitted.

## [1.0.2]

- Fixed: nothing could be drawn. An empty canvas has no content, so its
  SwiftUI stack was zero-sized and received no touch at all — the first stroke
  could never begin. The canvas now fills the space it is given from the start.
- `SignaturePadView` turns interactive dismissal off for the whole sheet, not
  only once a stroke is down, so a downward stroke never drags or dismisses
  it. The drag indicator goes with it; Cancel dismisses.
- Tests guarding that the canvas fills its space, empty or not.

## [1.0.1]

- `Signature` carries a stable `id` (`UUID`) and becomes `Identifiable`: it is
  saved straight into a model owned by the app, as a `Codable` property, with
  no intermediate type and no attachment key. JSON written by 1.0.0 is still
  read, with a fresh `id`.
- `Signature.signerName` removed, along with `signerName`, `asksForName` and
  `suggestedNames` from `SignaturePadConfiguration`: the sheet no longer asks
  for a name, the app keeps identity on its own side. Already saved JSON is
  still read, the name is simply ignored.
- `SignatureCanvas` is accessible: label, value, and the
  `allowsDirectInteraction` trait so it can be drawn on with VoiceOver on.
- `SignaturePadView` no longer closes on a downward swipe once a stroke is
  down: only Cancel abandons a signature in progress.
- Labels moved to a String Catalog, in English (the development language) and
  French, referenced through the symbols Xcode generates. **Visible change**:
  an app that does not declare French in its localizations now shows the sheet
  in English.
- Building the package now requires Xcode 26 or newer.
- Tests for the drawing, the controller, SwiftData persistence and the
  translations.

## [1.0.0]

First release as a standalone package.

- `Signature`: transparent PNG cropped to the strokes, plus the vector
  drawing, `Codable`.
- `SignatureStroke` / `SignatureDrawing`: strokes of variable width derived
  from the speed of the gesture, stored as JSON together with the size of the
  area they were drawn in.
- `SignaturePadView` and `SignaturePadConfiguration`: the complete sheet, with
  undo, redo, clear, and a confirm button disabled until something is drawn.
- `SignatureCanvas` and `SignatureCanvasController`, to build your own UI.
- `SignatureThumbnail`.
- The `signaturePad(item:)` and `signaturePrivacyScreen()` modifiers.
- Full SwiftUI: no `UIViewRepresentable`, no PencilKit, no external
  dependency. iOS 18.6+.
