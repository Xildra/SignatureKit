# Changelog

Semantic versioning. Once two projects depend on it, the rule matters more
than the number:

- **major**: a public API renamed, removed, or with a changed signature.
  Breaks the build for everyone else.
- **minor**: a purely additive change (new parameter with a default value,
  new type, new view).
- **patch**: a behavior fix, API unchanged.

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
- `SignaturePadView` turns interactive dismissal off entirely: the sheet's
  pan gesture used to win over the drawing gesture, so the sheet slid instead
  of a stroke being drawn. The drag indicator goes with it; Cancel dismisses.
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
