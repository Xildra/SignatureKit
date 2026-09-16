import SwiftUI

/// The complete signature sheet: drawing area, undo / redo / clear, and a
/// confirm button that stays disabled until something has been drawn.
public struct SignaturePadView: View {

    private let configuration: SignaturePadConfiguration
    private let onValidate: (Signature) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var canvas = SignatureCanvasController()

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

                pad
                tools

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(configuration.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text(.cancel) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { validate() } label: { Text(.done) }
                        .fontWeight(.semibold)
                        .disabled(canvas.isEmpty)
                }
            }
            .onAppear {
                canvas.minimumWidth = configuration.minimumWidth
                canvas.maximumWidth = configuration.maximumWidth
                canvas.load(configuration.existing?.strokeData)
            }
        }
        // A downward swipe must not throw away a signature in progress.
        .interactiveDismissDisabled(!canvas.isEmpty)
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
                        Text(.signAboveTheLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .allowsHitTesting(false)   // the line must not steal the gesture
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var tools: some View {
        HStack {
            Button { canvas.undo() } label: {
                Label { Text(.undo) } icon: { Image.undo }
            }
            .disabled(!canvas.canUndo)

            Button { canvas.redo() } label: {
                Label { Text(.redo) } icon: { Image.redo }
            }
            .disabled(!canvas.canRedo)

            Spacer()

            Button(role: .destructive) { canvas.clear() } label: {
                Label { Text(.clear) } icon: { Image.clear }
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
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onValidate(Signature(image: image, strokeData: canvas.drawingData()))
        dismiss()
    }
}
