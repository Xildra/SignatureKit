import SwiftUI

public extension View {

    /// Présente la feuille de signature pour l'élément en cours.
    ///
    /// Piloté par un `item` et non par un `Bool` : dans une liste, un booléen
    /// unique ouvre toujours la même ligne, et un booléen par ligne crée
    /// autant de feuilles.
    func signaturePad<Item: Identifiable>(
        item: Binding<Item?>,
        configuration: @escaping (Item) -> SignaturePadConfiguration,
        onValidate: @escaping (Item, Signature) -> Void
    ) -> some View {
        sheet(item: item) { value in
            SignaturePadView(configuration: configuration(value)) { signature in
                onValidate(value, signature)
            }
            .signaturePrivacyScreen()
            .presentationDragIndicator(.visible)
        }
    }

    /// Masque le contenu quand l'app quitte le premier plan.
    ///
    /// iOS photographie l'écran au passage en arrière-plan et **écrit cette
    /// image sur le disque** pour le sélecteur d'app. Une signature affichée
    /// s'y retrouve, hors de ton contrôle.
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
                            Image(systemName: "hand.raised.fill")
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
