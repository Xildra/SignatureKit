import SwiftUI

/// La feuille de signature complète : champ nom optionnel, zone de dessin,
/// annuler / rétablir / effacer, et un bouton Valider inactif tant que rien
/// n'a été tracé.
public struct SignaturePadView: View {

    private let configuration: SignaturePadConfiguration
    private let onValidate: (Signature) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var canvas = SignatureCanvasController()
    @State private var name = ""

    public init(configuration: SignaturePadConfiguration,
                onValidate: @escaping (Signature) -> Void) {
        self.configuration = configuration
        self.onValidate = onValidate
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if !configuration.subtitle.isEmpty {
                    Text(configuration.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                nameField
                pad
                tools

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(configuration.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider") { validate() }
                        .fontWeight(.semibold)
                        .disabled(canvas.isEmpty)
                }
            }
            .onAppear {
                name = configuration.signerName
                canvas.minimumWidth = configuration.minimumWidth
                canvas.maximumWidth = configuration.maximumWidth
                canvas.load(configuration.existing?.strokeData)
            }
        }
    }

    @ViewBuilder
    private var nameField: some View {
        if configuration.asksForName {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Nom du signataire", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                if !configuration.suggestedNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(configuration.suggestedNames, id: \.self) { suggestion in
                                Button(suggestion) { name = suggestion }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
        }
    }

    private var pad: some View {
        SignatureCanvas(controller: canvas, ink: configuration.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .secondarySystemBackground))
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(.tertiary)
                        .frame(height: 1)
                    if canvas.isEmpty {
                        Text("Signez au-dessus de la ligne")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .allowsHitTesting(false)   // la ligne ne doit pas voler le geste
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var tools: some View {
        HStack {
            Button { canvas.undo() } label: {
                Label("Annuler le trait", systemImage: "arrow.uturn.backward")
            }
            .disabled(!canvas.canUndo)

            Button { canvas.redo() } label: {
                Label("Rétablir", systemImage: "arrow.uturn.forward")
            }
            .disabled(!canvas.canRedo)

            Spacer()

            Button(role: .destructive) { canvas.clear() } label: {
                Label("Tout effacer", systemImage: "trash")
            }
            .disabled(canvas.isEmpty)
        }
        .font(.footnote)
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    @MainActor
    private func validate() {
        guard let image = canvas.image(ink: configuration.ink,
                                       scale: configuration.exportScale,
                                       margin: configuration.exportMargin) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onValidate(Signature(signerName: trimmed.isEmpty ? configuration.signerName : trimmed,
                             image: image,
                             strokeData: canvas.drawingData()))
        dismiss()
    }
}
