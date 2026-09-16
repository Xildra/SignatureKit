import SwiftUI

public extension View {

    /// Presents the signature sheet for the current item.
    ///
    /// Driven by an `item` rather than a `Bool`: in a list, a single boolean
    /// always opens the same row, and one boolean per row creates as many
    /// sheets.
    func signaturePad<Item: Identifiable>(
        item: Binding<Item?>,
        configuration: @escaping (Item) -> SignaturePadConfiguration,
        onValidate: @escaping (Item, Signature) -> Void
    ) -> some View {
        sheet(item: item) { value in
            SignaturePadView(configuration: configuration(value)) { signature in
                onValidate(value, signature)
            }
            // No drag indicator: it would advertise a swipe the sheet refuses.
            .signaturePrivacyScreen()
        }
    }

    /// Hides the content when the app leaves the foreground.
    ///
    /// iOS photographs the screen as the app goes to the background and
    /// **writes that image to disk** for the app switcher. A signature left
    /// on screen ends up there, outside the app's control.
    func signaturePrivacyScreen() -> some View {
        modifier(PrivacyScreen())
    }
}

private struct PrivacyScreen: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .overlay {
                if scenePhase != .active {
                    Rectangle()
                        .fill(.regularMaterial)
                        .overlay {
                            Image.privacy
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                        }
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: scenePhase)
    }
}
