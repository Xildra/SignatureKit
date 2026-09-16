# SignatureKit

Handwritten signature capture for iOS, **full SwiftUI**: no
`UIViewRepresentable`, no PencilKit, no external dependency.

- iOS 18.6+
- Variable stroke width, derived from the speed of the gesture
- Transparent PNG export cropped to the strokes **and** a vector drawing
  (`SignatureDrawing`, JSON, a few KB)
- Persistence is yours: `Signature` is `Codable` and `Identifiable`, and is
  stored as it is (SwiftData, JSON, API, file…)
- Usable with VoiceOver turned on
- Labels in English and French (String Catalog)

## Installation

Xcode → File → Add Package Dependencies → the repository URL, or locally:
File → Add Package Dependencies → Add Local… → this folder.

```swift
.package(url: "https://…/SignatureKit.git", from: "1.0.0")
```

## Usage

### One signature per row of a list

```swift
import SignatureKit
import SwiftUI

struct Signer: Identifiable {
    let id = UUID()
    let name: String
}

struct SignersView: View {
    let signers: [Signer]
    @State private var signatures: [Signer.ID: Signature] = [:]
    @State private var current: Signer?

    var body: some View {
        List(signers) { signer in
            HStack {
                Text(signer.name)
                Spacer()
                if let signature = signatures[signer.id], signature.isSigned {
                    SignatureThumbnail(signature)
                        .onTapGesture { current = signer }
                } else {
                    Button("Sign") { current = signer }
                }
            }
        }
        .signaturePrivacyScreen()
        .signaturePad(item: $current) { signer in
            SignaturePadConfiguration(title: signer.name,
                                      existing: signatures[signer.id])
        } onValidate: { signer, signature in
            signatures[signer.id] = signature
        }
    }
}
```

### Persistence

The package ships no storage type: the model belongs to the app, which saves
`Signature` values directly.

```swift
@Model final class Document {
    var signatures: [Signature] = []
}

// On confirmation
document.signatures.append(signature)

// To reopen the sheet on an existing signature
let existing = document.signatures.first { $0.id == id }
```

Every `Signature` carries an `id` (`UUID`) created on init and kept
afterwards, `clear()` included: where a signature sits in the app does not
move when it is drawn again.

## Notes

- `signaturePad(item:)` is driven by an item, not by a `Bool`: in a list, a
  single boolean always opens the same row.
- The package captures no identity. Who signs, in what capacity, under which
  name: all of that belongs to the app, which keeps the `Signature` next to
  the rest. The sheet title stays free — that is where a name goes.
- The sheet cannot be swiped away, so a downward stroke never drags or
  dismisses it. Cancel is the way out — which also protects a signature in
  progress.
- `signaturePrivacyScreen()` hides the content when the app goes to the
  background. iOS snapshots the screen and writes that image to disk; a
  signature left on screen would end up there.
- `SignatureCanvas` fits anywhere, `ScrollView` included.
- The drawing is saved together with the size of the area it was drawn in: a
  signature made on iPhone reloads correctly on iPad.
- Labels live in `Sources/SignatureKit/Resources/Localizable.xcstrings`, in
  English (the development language) and French. Adding a language happens in
  that catalog, without touching the code.
- Catalog entries are written by hand: Xcode generates one symbol per entry
  (`Text(.done)`, `Text(.signAboveTheLine)`) that finds the package bundle on
  its own. A missing or renamed entry does not compile.
- The language shown follows the **app**, not the device: an app that does not
  declare French in its localizations (Project → Info → Localizations) shows
  the sheet in English, even on an iPhone set to French.

## Data and privacy

The package stores nothing. It keeps the strokes in memory, renders a PNG,
and hands both to your callback: no file, no cache, no user defaults, no
network call. It imports SwiftUI, UIKit, Foundation and CoreGraphics, and
nothing else. Where a signature ends up is entirely the app's decision.

What is worth deciding on the app side:

- **iCloud sync** only happens if asked for: leave `cloudKitDatabase` alone on
  `ModelConfiguration`, and do not add the iCloud capability.
- **Device backups** include the app container by default. Exclude the store
  with `isExcludedFromBackup` if a signature must never leave the device.
- **File protection** defaults to `completeUntilFirstUserAuthentication`.
  Raise it to `complete` to keep signatures unreadable while the device is
  locked — background work can no longer read them either.
- **The app switcher snapshot** is the one copy iOS writes outside the app's
  control. `signaturePrivacyScreen()` exists for exactly that.

A signature kept as a `Codable` property lives inside the store file itself:
one file to exclude from backups and to protect. `@Attribute(.externalStorage)`
spreads it over the store *and* its support directory — two places to
remember, both inside the app container.

## Building and testing

The package depends on UIKit: it only builds for iOS.

- In Xcode, pick an iOS simulator as the destination. “My Mac” gives
  `No such module 'UIKit'`.
- `swift build` builds for macOS and fails for the same reason. From the
  command line, go through `xcodebuild`:

```bash
xcodebuild test -scheme SignatureKit -destination 'platform=iOS Simulator,name=iPhone 17'
```

If `xcodebuild` answers that it requires Xcode, `xcode-select` points at the
Command Line Tools:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Publishing and reusing

Tag every published version:

```bash
git tag 1.0.0 && git push --tags
```

In each app: **Add Package Dependencies** → the URL → *Up to Next Major
Version*. Without a tag, Xcode sees no version and forces a branch, which
makes builds unreproducible.

### Iterating on the package from an app

Drag the local folder into the project window: Xcode gives the local package
precedence over the remote dependency of the same name. Edit, test in the real
app, then remove the folder once the tag is pushed — without ever touching the
dependency declaration.

### What must stay out

The main threat to a shared package is the convenient addition: a model type
from an app, a business role, a rule along the lines of “this document needs
N signatures”. Simple rule: if the code speaks the vocabulary of a trade, it
belongs to the app, not here.

### Things to watch

- `Package.resolved`: commit it in apps, not in the package.
- Stored inside a SwiftData model, a `Signature` carries its PNG in the row.
  For many signatures or heavy exports, declare a model on the app side with
  `@Attribute(.externalStorage) var pngData: Data?` and rebuild a `Signature`
  only when displaying it.
- The `.iOS("18.6")` floor applies to every consumer. Nothing in the code
  needs more than iOS 18: `onGeometryChange` (18.0) is the most recent API
  used. Raise it if every app is already higher.
- A new label goes into the catalog first (the **+** button), then is used
  through its symbol after a build.
- The generated symbols require **Xcode 26 or newer** in every app that builds
  the package.

## License

MIT.
