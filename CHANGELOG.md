# Changelog

Semantic versioning. Once two projects depend on it, the rule matters more
than the number:

- **major**: a public API renamed, removed, or with a changed signature.
  Breaks the build for everyone else.
- **minor**: a purely additive change (new parameter with a default value,
  new type, new view).
- **patch**: a behavior fix, API unchanged.

## [1.0.0]

- `Signature.signerName` removed, along with `signerName`, `asksForName` and
  `suggestedNames` from `SignaturePadConfiguration`: the sheet no longer asks
  for a name, the app keeps its own next to the signature. Already saved JSON
  is still read, the name is simply ignored.
- `Signature` carries a stable `id` (`UUID`) and becomes `Identifiable`: it is
  saved straight into a model owned by the app, with no intermediate type and
  no attachment key. JSON written by earlier versions is still read, with a
  fresh `id`.
- `SignatureCanvas` is accessible: label, value, and the
  `allowsDirectInteraction` trait so it can be drawn on with VoiceOver on.
- `SignaturePadView` no longer closes on a swipe once a stroke is down.
- Labels localized through a String Catalog: English (the development
  language) and French, referenced by the symbols Xcode generates.
  **Visible change**: an app that does not declare French in its localizations
  now shows the sheet in English.
- Building the package: Xcode 26 or newer.
- Tests for the drawing (`SignatureDrawing`), the controller and the
  translations.
- Code and documentation stripped of every app-specific word.

  **Breaking.** Full SwiftUI: PencilKit is gone.

- `SignatureCanvas` becomes a SwiftUI `View`; no more `UIViewRepresentable`.
- New stroke model `SignatureStroke` / `SignatureDrawing` (JSON). The
  `strokeData` produced by 1.0 (`PKDrawing` format) is no longer read — the
  PNGs already saved stay valid.
- `SignaturePadConfiguration.strokeWidth` replaced by `minimumWidth` and
  `maximumWidth`.
- Floor raised to iOS 18.6.

- `Signature`: PNG + `PKDrawing` vector strokes, `Codable`.
- `SignaturePadView` and `SignaturePadConfiguration`.
- `SignatureCanvas` and `SignatureCanvasController`, to build your own UI.
- `SignatureThumbnail`.
- The `signaturePad(item:)` and `signaturePrivacyScreen()` modifiers.
